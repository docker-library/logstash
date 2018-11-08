#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

travisEnv=
for version in "${versions[@]}"; do
	major="${version%%.*}"
	debRepo="https://artifacts.elastic.co/packages/${major}.x/apt"
	logstashPath='/usr/share/logstash/bin'
	tarballUrlBase='https://artifacts.elastic.co/downloads'
	if [ "$major" -lt 5 ]; then
		debRepo="http://packages.elastic.co/logstash/$version/debian"
		logstashPath='/opt/logstash/bin'
		tarballUrlBase='https://download.elastic.co/logstash'
	fi

	fullVersion="$(curl -fsSL "$debRepo/dists/stable/main/binary-amd64/Packages.gz" | gunzip | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "logstash" && $1 == "Version" { print $2 }' | sort -rV | grep -F 1:$version | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	# convert "1:5.0.2-1" over to "5.0.2"
	plainVersion="${fullVersion%%-*}" # strip non-upstream-version
	plainVersion="${plainVersion##*:}" # strip epoch
	tilde='~'; plainVersion="${plainVersion//$tilde/-}" # replace '~' with '-'

	if [ $major -ge 6 ]; then
		# Use the "upstream" Dockerfile, which rebundles the existing image from Elastic.
		upstreamImage="docker.elastic.co/logstash/logstash:$plainVersion"
		
		# Parse image manifest for sha
		authToken="$(curl -fsSL 'https://docker-auth.elastic.co/auth?service=token-service&scope=repository:logstash/logstash:pull' | jq -r .token)"
		digest="$(curl --head -fsSL -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -H "Authorization: Bearer $authToken" "https://docker.elastic.co/v2/logstash/logstash/manifests/$plainVersion" | tr -d '\r' | gawk -F ':[[:space:]]+' '$1 == "Docker-Content-Digest" { print $2 }')"

		# Format image reference (image@sha)
		upstreamImageDigest="$upstreamImage@$digest"

		(
			set -x
			sed '
				s!%%LOGSTASH_VERSION%%!'"$plainVersion"'!g;
				s!%%UPSTREAM_IMAGE_DIGEST%%!'"$upstreamImageDigest"'!g;
			' Dockerfile-upstream.template > "$version/Dockerfile"
		)
		travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
	else
		(
			set -x
			cp docker-entrypoint.sh "$version/"
			sed '
				s!%%LOGSTASH_VERSION%%!'"$plainVersion"'!g;
				s!%%LOGSTASH_DEB_REPO%%!'"$debRepo"'!g;
				s!%%LOGSTASH_DEB_VERSION%%!'"$fullVersion"'!g;
				s!%%LOGSTASH_PATH%%!'"$logstashPath"'!g;
			' Dockerfile-debian.template > "$version/Dockerfile"
		)
	
		if [ -d "$version/alpine" ]; then
			tarball="$tarballUrlBase/logstash/logstash-${plainVersion}.tar.gz"
			tarballAsc="${tarball}.asc"
			if ! wget --quiet --spider "$tarballAsc"; then
				tarballAsc=
			fi
			tarballSha1=
			for sha1Url in "${tarball}.sha1" "${tarball}.sha1.txt"; do
				if sha1="$(wget -qO- "$sha1Url")"; then
					tarballSha1="${sha1%% *}"
					break
				fi
			done
			(
				set -x
				cp docker-entrypoint.sh "$version/alpine/"
				sed -i 's/gosu/su-exec/g' "$version/alpine/docker-entrypoint.sh"
				sed \
					-e 's!%%LOGSTASH_VERSION%%!'"$plainVersion"'!g' \
					-e 's!%%LOGSTASH_PATH%%!'"$logstashPath"'!g' \
					-e 's!%%LOGSTASH_TARBALL%%!'"$tarball"'!g' \
					-e 's!%%LOGSTASH_TARBALL_ASC%%!'"$tarballAsc"'!g' \
					-e 's!%%LOGSTASH_TARBALL_SHA1%%!'"$tarballSha1"'!g' \
					Dockerfile-alpine.template > "$version/alpine/Dockerfile"
			)
			travisEnv='\n  - VERSION='"$version VARIANT=alpine$travisEnv"
		fi
		travisEnv='\n  - VERSION='"$version VARIANT=$travisEnv"
	fi
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
