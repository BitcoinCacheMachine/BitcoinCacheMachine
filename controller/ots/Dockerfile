ARG BCM_VERSION

FROM bcm-trezor:${BCM_VERSION}


USER root
WORKDIR /root

RUN apt-get install python3 python3-dev python3-pip python3-setuptools python3-wheel

RUN git clone https://github.com/opentimestamps/opentimestamps-client /ots
WORKDIR /ots
RUN git checkout master
RUN python3 /ots/setup.py install
