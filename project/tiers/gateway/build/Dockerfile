FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y wait-for-it iproute2 curl dnsutils wait-for-it iputils-ping iproute2

# help scripts
RUN mkdir /bcm
ADD proxy_ip_determinant.sh /bcm/proxy_ip_determinant.sh
RUN chmod 0755 /bcm/proxy_ip_determinant.sh

ADD wait_for_gogo.sh /bcm/wait_for_gogo.sh
RUN chmod 0755 /bcm/wait_for_gogo.sh
