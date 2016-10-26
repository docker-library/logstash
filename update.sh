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
	travisEnv='\n  - VERSION='"$version$travisEnv"

	major="${version%%.*}"
	debRepo="https://artifacts.elastic.co/packages/${major}.x/apt"
	logstashPath='/usr/share/logstash/bin'
	if [ "$major" -lt 5 ]; then
		debRepo="http://packages.elastic.co/logstash/$version/debian"
		logstashPath='/opt/logstash/bin'
	fi

	fullVersion="$(curl -fsSL "$debRepo/dists/stable/main/binary-amd64/Packages.gz" | gunzip | awk -F ': ' '$1 == "Package" { pkg = $2 } pkg == "logstash" && $1 == "Version" { print $2 }' | sort -rV | head -n1)"
	if [ -z "$fullVersion" ]; then
		echo >&2 "warning: cannot find full version for $version"
		continue
	fi
	(
		set -x
		cp docker-entrypoint.sh "$version/"
		sed '
			s!%%LOGSTASH_DEB_REPO%%!'"$debRepo"'!g;
			s!%%LOGSTASH_VERSION%%!'"$fullVersion"'!g;
			s!%%LOGSTASH_PATH%%!'"$logstashPath"'!g;
		' Dockerfile.template > "$version/Dockerfile"
	)
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
