FROM elasticsearch:1.4

ENV LOGSTASH_VERSION 1.4.2

RUN curl https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VERSION.tar.gz | tar zx -C /usr/share

ENV PATH=$PATH:/usr/share/logstash-$LOGSTASH_VERSION/bin

CMD ["logstash"]
