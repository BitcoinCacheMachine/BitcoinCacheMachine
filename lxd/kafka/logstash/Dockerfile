FROM docker.elastic.co/logstash/logstash-oss:6.2.4

RUN logstash-plugin install logstash-output-kafka logstash-input-gelf


CMD ["-f", "/etc/logstash.conf"]
