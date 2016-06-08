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
	travisEnv='\n  - VERSION='"$version\n  - VERSION=$version"'/alpine'"$travisEnv"

	fullVersion="$(curl -fsSL "http://packages.elastic.co/logstash/$version/debian/dists/stable/main/binary-amd64/Packages" | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "logstash" && $1 == "Version" { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	(
		set -x
		cp docker-entrypoint.sh "$version/"
		sed '
			s/%%LOGSTASH_MAJOR%%/'"$version"'/g;
			s/%%LOGSTASH_VERSION%%/'"$fullVersion"'/g;
		' Dockerfile.template > "$version/Dockerfile"
	)
	
	fullVersionAlpine="$(curl -fsSL https://www.elastic.co/downloads/past-releases/feed | xmlstarlet sel -t -v 'rss/channel/item/title'|grep 'Logstash '$version| awk -F' ' '{print $2}'|sort -rV |head -n1)"
	echo $fullVersionAlpine
	echo https://download.elastic.co/logstash/logstash/logstash-$fullVersionAlpine.tar.gz.sha1.txt
	sha1="$(curl -fsSL "https://download.elastic.co/logstash/logstash/logstash-$fullVersionAlpine.tar.gz.sha1.txt" | grep -o -E -e "[0-9a-f]{40}")"

	if [ -z "$fullVersionAlpine" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	(
		[ -d "$version/alpine" ] || mkdir "$version/alpine"
		set -x
		cp docker-entrypoint-alpine.sh "$version/alpine/"
		sed '
			s/%%LOGSTASH_MAJOR%%/'"$version"'/g;
			s/%%LOGSTASH_VERSION%%/'"$fullVersionAlpine"'/g;
			s/%%LOGSTASH_TAR_SHA1%%/'"$sha1"'/g;
		' Dockerfile-alpine.template > "$version/alpine/Dockerfile"
	)
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
