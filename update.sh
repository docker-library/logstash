#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

version=$(curl -sSL 'http://logstash.net' \
	| sed -rn '0,/.*?\/docs\/.\..\..\/learn.*/s/.*?\/docs\/(.\..\..)\/learn.*/\1/gp')

sed -ri -e 's/^(ENV LOGSTASH_VERSION) .*/\1 '"$version"'/' "Dockerfile"

