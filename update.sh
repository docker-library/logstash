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

	fullVersion="$(curl -fsSL "$debRepo/dists/stable/main/binary-amd64/Packages.gz" | gunzip | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "logstash" && $1 == "Version" { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	# convert "1:5.0.2-1" over to "5.0.2"
	plainVersion="${fullVersion%%-*}" # strip non-upstream-version
	plainVersion="${plainVersion##*:}" # strip epoch
	tilde='~'; plainVersion="${plainVersion//$tilde/-}" # replace '~' with '-'

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
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
