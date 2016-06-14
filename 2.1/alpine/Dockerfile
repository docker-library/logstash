FROM alpine:3.4

RUN addgroup -S logstash && adduser -S -G logstash logstash

RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> '/etc/apk/repositories'

RUN apk update
RUN apk add --no-cache ca-certificates curl openjdk8 gosu@testing libzmq

# the "ffi-rzmq-core" gem is very picky about where it looks for libzmq.so
RUN mkdir -p /usr/local/lib \
	&& ln -s /usr/lib/*/libzmq.so.3 /usr/local/lib/libzmq.so

ENV LOGSTASH_MAJOR 2.1
ENV LOGSTASH_VERSION 2.1.3
ENV LOGSTASH_TAR_SHA1 283f6d8842df52c7d69f77b5c6d4755ee942b291

RUN \
  adduser -D -S elasticsearch
RUN \
  mkdir -p /opt && \
  cd /tmp && \
  curl -L https://download.elastic.co/logstash/logstash/logstash-$LOGSTASH_VERSION.tar.gz > logstash-$LOGSTASH_VERSION.tar.gz && \
  echo "$LOGSTASH_TAR_SHA1  logstash-$LOGSTASH_VERSION.tar.gz" | sha1sum -c - && \
  tar -xzf logstash-$LOGSTASH_VERSION.tar.gz && \
  rm -rf logstash-$LOGSTASH_VERSION.tar.gz && \
  mv logstash-$LOGSTASH_VERSION /opt/logstash && \
  ln -s /opt/logstash/bin/logstash /usr/local/bin/logstash

COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["logstash", "agent"]
