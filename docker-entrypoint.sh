#!/bin/bash

set -e

# Add logstash as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- logstash "$@"
fi

# Run as user "logstash" if the command is "logstash"
if [ "$1" = 'logstash' ]; then
	setcap 'cap_net_bind_service=+ep' $(readlink -f "$(which java)")
	set -- gosu logstash "$@"
fi

exec "$@"
