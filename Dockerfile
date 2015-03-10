FROM java:7-jre

# http://www.logstash.net/docs/1.4.2/repositories
# http://packages.elasticsearch.org/GPG-KEY-elasticsearch
RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV LOGSTASH_MAJOR 1.4
ENV LOGSTASH_VERSION 1.4.2-1-2c0f5a1

RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_MAJOR}/debian stable main" > /etc/apt/sources.list.d/logstash.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends logstash=$LOGSTASH_VERSION \
	&& rm -rf /var/lib/apt/lists/*

ENV PATH /opt/logstash/bin:$PATH

CMD ["logstash"]
