ARG BCM_VERSION

FROM bcm-trezor:${BCM_VERSION}

USER root
WORKDIR /root
ENV GNUPGHOME=/root/.gnupg

RUN apt-get update
RUN apt-get install -y --no-install-recommends python3-pyqt5 wget
RUN apt-get install -y --no-install-recommends libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-video-all && rm -rf /var/lib/apt/lists/*


RUN git clone https://github.com/romanz/trezor-agent /tmp/trezor-agent
WORKDIR /tmp/trezor-agent
RUN git checkout master
RUN pip3 install --user -e /tmp/trezor-agent/agents/ledger

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER user
WORKDIR /home/user
ENV GNUPGHOME=/home/user/.gnupg

COPY ThomasV.asc ThomasV.asc
RUN gpg --import ThomasV.asc
RUN wget https://download.electrum.org/3.3.6/Electrum-3.3.6.tar.gz
RUN wget https://download.electrum.org/3.3.6/Electrum-3.3.6.tar.gz.asc
RUN gpg --verify Electrum-3.3.6.tar.gz.asc

RUN tar -xvf Electrum-3.3.6.tar.gz

RUN rm Electrum-3.3.6.tar.gz
RUN rm Electrum-3.3.6.tar.gz.asc

#ENV XDG_RUNTIME_DIR=/run/user/1000

ENTRYPOINT [ "/entrypoint.sh" ]
