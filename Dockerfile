FROM elasticsearch:1.4

ENV LOGSTASH_VERSION 1.4.2

#From https://download.elasticsearch.org/logstash/logstash/logstash-1.4.2.tar.gz.sha1.txt
ENV LOGSTASH_DOWNLOAD_SHA1 d59ef579c7614c5df9bd69cfdce20ed371f728ff
ENV LOGSTASH_HOME /usr/local/logstash

RUN curl -o logstash.tar.gz https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VERSION.tar.gz \
	&& echo "$LOGSTASH_DOWNLOAD_SHA1 logstash.tar.gz" | sha1sum -c - \
	&& mkdir $LOGSTASH_HOME \
	&& tar -zxf logstash.tar.gz --strip-components 1 -C $LOGSTASH_HOME \
	&& rm logstash.tar.gz

ENV PATH=$PATH:$LOGSTASH_HOME/bin

CMD ["logstash"]
