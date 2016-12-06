FROM openjdk:8-jre-alpine

# ensure logstash user exists
RUN addgroup -S logstash && adduser -S -G logstash logstash

# install plugin dependencies
RUN apk add --no-cache \
# env: can't execute 'bash': No such file or directory
		bash \
		libzmq

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2'

# https://www.elastic.co/guide/en/logstash/5.0/installing-logstash.html#_apt
# https://artifacts.elastic.co/GPG-KEY-elasticsearch
ENV GPG_KEY 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV LOGSTASH_PATH /opt/logstash/bin
ENV PATH $LOGSTASH_PATH:$PATH

ENV LOGSTASH_VERSION 2.4.1
ENV LOGSTASH_TARBALL="https://download.elastic.co/logstash/logstash/logstash-2.4.1.tar.gz" \
	LOGSTASH_TARBALL_ASC="" \
	LOGSTASH_TARBALL_SHA1="5ee4f3fa0ad4b182b3f00b4181a20c4e31a907b4"

RUN set -ex; \
	\
	if [ -z "$LOGSTASH_TARBALL_SHA1" ] && [ -z "$LOGSTASH_TARBALL_ASC" ]; then \
		echo >&2 'error: have neither a SHA1 _or_ a signature file -- cannot verify download!'; \
		exit 1; \
	fi; \
	\
	apk add --no-cache --virtual .fetch-deps \
		ca-certificates \
		gnupg \
		openssl \
		tar \
	; \
	\
	wget -O logstash.tar.gz "$LOGSTASH_TARBALL"; \
	\
	if [ "$LOGSTASH_TARBALL_SHA1" ]; then \
		echo "$LOGSTASH_TARBALL_SHA1 *logstash.tar.gz" | sha1sum -c -; \
	fi; \
	\
	if [ "$LOGSTASH_TARBALL_ASC" ]; then \
		wget -O logstash.tar.gz.asc "$LOGSTASH_TARBALL_ASC"; \
		export GNUPGHOME="$(mktemp -d)"; \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY"; \
		gpg --batch --verify logstash.tar.gz.asc logstash.tar.gz; \
		rm -r "$GNUPGHOME" logstash.tar.gz.asc; \
	fi; \
	\
	dir="$(dirname "$LOGSTASH_PATH")"; \
	\
	mkdir -p "$dir"; \
	tar -xf logstash.tar.gz --strip-components=1 -C "$dir"; \
	rm logstash.tar.gz; \
	\
	apk del .fetch-deps; \
	\
	export LS_SETTINGS_DIR="$dir/config"; \
# if the "log4j2.properties" file exists (logstash 5.x), let's empty it out so we get the default: "logging only errors to the console"
	if [ -f "$LS_SETTINGS_DIR/log4j2.properties" ]; then \
		cp "$LS_SETTINGS_DIR/log4j2.properties" "$LS_SETTINGS_DIR/log4j2.properties.dist"; \
		truncate -s 0 "$LS_SETTINGS_DIR/log4j2.properties"; \
	fi; \
	\
# set up some file permissions
	for userDir in \
		"$dir/config" \
		"$dir/data" \
	; do \
		if [ -d "$userDir" ]; then \
			chown -R logstash:logstash "$userDir"; \
		fi; \
	done; \
	\
	logstash --version

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["-e", ""]
