#!/usr/bin/env bash
set -Eeuo pipefail

# "docker history", but ignoring/munging known problematic bits for the purposes of creating image diffs

docker image history --no-trunc --format '{{ .CreatedBy }}' "$@" \
	| tac \
	| sed -r 's!^/bin/sh[[:space:]]+-c[[:space:]]+(#[(]nop[)][[:space:]]+)?!!' \
	| awk '
		# ignore the first ADD of the base image (base image changes unnecessarily break our diffs)
		NR == 1 && $1 == "ADD" && $4 == "/" { next }
		# TODO consider instead just removing the checksum in $3

		# ignore obviously "centos" LABEL instructions (include a timestamp, so base image changes unnecessarily break our diffs)
		$1 == "LABEL" && / org.opencontainers.image.vendor=CentOS | org.label-schema.vendor=CentOS / { next }

		# just ignore the default CentOS CMD value (not relevant to our needs)
		$0 == "CMD [\"/bin/bash\"]" { next }

		# in logstash, Elastic builds pull artifacts from "http://localhost:8000" instead of "https://artifacts.elastic.co/downloads/logstash"
		/localhost:8000\/logstash/ { gsub(/http:\/\/localhost:8000\/logstash/, "https://artifacts.elastic.co/downloads/logstash/logstash") }

		# sane and sanitized, print it!
		{ print }
	'
