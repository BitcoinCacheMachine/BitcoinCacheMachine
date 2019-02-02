FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y wait-for-it iproute2 curl dnsutils wait-for-it iputils-ping iproute2
