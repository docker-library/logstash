#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

version='1.4'
fullVersion="$(curl -sSL "http://packages.elasticsearch.org/logstash/$version/debian/dists/stable/main/binary-amd64/Packages.gz" | gunzip | awk -F ': *' '$1 == "Package" { pkg = $2 } pkg == "logstash" && $1 == "Version" { print $2 }' | sort -V | tail -1)"

sed -ri \
	-e 's/^(ENV LOGSTASH_MAJOR) .*/\1 '"$version"'/' \
	-e 's/^(ENV LOGSTASH_VERSION) .*/\1 '"$fullVersion"'/' Dockerfile

