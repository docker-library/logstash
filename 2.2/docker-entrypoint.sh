#!/bin/bash

if [ -n "$OTHER_PLUGINS" ]; then
	pluginarr=$(echo $OTHER_PLUGINS | tr "," "\n")
	plugincount=$(echo $pluginarr | grep -c "\n")
	if [ $plugincount -lt 1 ]; then
		plugin=$pluginarr
		itemcount=$(plugin list | grep -c $plugin)
		echo "$plugin found $itemcount times"
		if [ $itemcount -lt 1 ]; then
			echo "Installing $plugin"
			echo $(plugin install $plugin)
		fi
	else
		echo $pluginarr
		for plugin in $pluginarr
		do
			itemcount=$(plugin list | grep -c $plugin)
			echo "$plugin found $itemcount times"
			if [ $itemcount -lt 1 ]; then
				echo "Installing $plugin"
				echo $(plugin install $plugin)
			fi
		done
	fi
fi

set -e

# Add logstash as command if needed
if [ "${1:0:1}" = '-' ]; then
	set -- logstash "$@"
fi

# Run as user "logstash" if the command is "logstash"
if [ "$1" = 'logstash' ]; then
	set -- gosu logstash "$@"
fi

exec "$@"
