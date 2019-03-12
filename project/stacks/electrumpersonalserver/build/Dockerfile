FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update
RUN apt-get install -y python3-pip

RUN git clone https://github.com/chris-belcher/electrum-personal-server /root/.eps
WORKDIR /root/.eps
RUN git checkout tags/eps-v0.1.6

RUN pip3 install --user .

WORKDIR /root/.eps
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]