#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
url='git://github.com/docker-library/logstash'
commit=$(git log -1 --format="format:%H" -- Dockerfile)
debVersion="$(grep -m1 'ENV LOGSTASH_VERSION' Dockerfile | cut -d' ' -f3)"
fullVersion="${debVersion%%[-]*}" # strip "debian version"
fullVersion="${fullVersion##*:}" # strip epoch
version="${fullVersion%[.]*}"

echo '# maintainer: InfoSiftr <github@infosiftr.com> (@infosiftr)'
echo
#echo "$debVersion: ${url}@${commit}"
echo "$fullVersion: ${url}@${commit}"
echo "$version: ${url}@${commit}"
echo "latest: ${url}@${commit}"

