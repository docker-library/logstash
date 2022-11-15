#!/usr/bin/env bash
set -Eeuo pipefail

# "docker history", but ignoring/munging known problematic bits for the purposes of creating image diffs

docker image history --no-trunc --format '{{ .CreatedBy }}' "$@" \
	| tac \
	| sed -r 's!^/bin/sh[[:space:]]+-c[[:space:]]+(#[(]nop[)][[:space:]]+)?!!' \
	| gawk '
		# munge the checksum of the first ADD of the base image (base image changes unnecessarily break our diffs)
		NR == 1 && $1 == "ADD" && $4 == "/" { $2 = "-" }

		# remove "org.label-schema.build-date" and "org.opencontainers.image.created" (https://github.com/elastic/dockerfiles/pull/101#pullrequestreview-879623350)
		$1 == "LABEL" { gsub(/ (org[.]label-schema[.]build-date|org[.]opencontainers[.]image[.]created)=[^ ]+( [0-9:+-]+)?/, "") }

		# in logstash, Elastic builds pull artifacts from "http://localhost:8000" instead of "https://artifacts.elastic.co/downloads/logstash"
		/localhost:8000\/logstash/ { gsub(/http:\/\/localhost:8000\/logstash/, "https://artifacts.elastic.co/downloads/logstash/logstash") }

		# sane and sanitized, print it!
		{ print }
	'
