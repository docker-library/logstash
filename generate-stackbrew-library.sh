#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
url='git://github.com/docker-library/logstash'
commit=$(git log -1 --format="format:%H" -- Dockerfile)
fullVersion="$(grep -m1 'ENV LOGSTASH_VERSION' Dockerfile | cut -d' ' -f3)"
version="${fullVersion%[.-]*}"

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'
echo "$version: ${url}@${commit}"
echo "latest: ${url}@${commit}"

