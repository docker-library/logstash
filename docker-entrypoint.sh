#!/bin/bash

set -e

# Add logstash as command if needed
if [[ "$1" == -* ]]; then
    set -- logstash "$@"
else 
    # Run as user "logstash" if the command is "logstash"
    if [ "$1" == logstash ]; then
        set -- gosu logstash "$@"
    else
        # As argument is not related to logstash, then
        # assume that user wants to run their own process,
        # for example a `bash` shell to explore this image
        exec "$@"
    fi
fi

# Use default config if CONFIGSTRING or CONFIGFILE is not provided
if [[ "$*" == *-f* ]] || [[ "$*" == *--config* ]] || [[ "$*" == *-e* ]]; then
    exec "$@"
else 
    exec "$@" -f /usr/share/logstash/config/logstash.conf
fi
