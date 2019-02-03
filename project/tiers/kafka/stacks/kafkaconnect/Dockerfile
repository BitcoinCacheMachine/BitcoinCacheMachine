FROM confluentinc/cp-kafka-connect:5.1.0
#bcm-kafka-connect:latest
RUN mkdir -p /usr/local/share/kafka/plugins
ADD ./syslog/* /usr/local/share/kafka/plugins/
ENV CLASSPATH=/usr/local/share/kafka/plugins