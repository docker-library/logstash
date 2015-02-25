#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
pattern='.*?\/docs\/([0-9]+\.[0-9]+\.[0-9]+)\/learn.*'
version=$(curl -sSL 'http://logstash.net' \
	| sed -rn "0,/${pattern}/s/${pattern}/\1/gp")
shaprime=$(curl -sSL "https://download.elasticsearch.org/logstash/logstash/logstash-${version}.tar.gz.sha1.txt" | sed -r -e 's/^(.+?)\s\s.*/\1/')

sed -ri \
	-e 's/^(ENV LOGSTASH_VERSION) .*/\1 '"$version"'/' \
	-e 's/^(ENV LOGSTASH_DOWNLOAD_SHA1) .*/\1 '"$shaprime"'/' "Dockerfile"

