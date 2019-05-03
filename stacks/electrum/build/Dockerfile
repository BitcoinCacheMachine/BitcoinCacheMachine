ARG BCM_VERSION

FROM bcm-trezor:${BCM_VERSION}

USER root
WORKDIR /root
ENV GNUPGHOME=/root/.gnupg

RUN apt-get update
RUN apt-get install -y python3-pyqt5 wget
RUN apt-get install -y libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-video-all && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER user
WORKDIR /home/user
ENV GNUPGHOME=/home/user/.gnupg

COPY ThomasV.asc ThomasV.asc
RUN gpg --import ThomasV.asc
RUN wget https://download.electrum.org/3.3.4/Electrum-3.3.4.tar.gz
RUN wget https://download.electrum.org/3.3.4/Electrum-3.3.4.tar.gz.asc
RUN gpg --verify Electrum-3.3.4.tar.gz.asc

RUN tar -xvf Electrum-3.3.4.tar.gz

RUN rm Electrum-3.3.4.tar.gz
RUN rm Electrum-3.3.4.tar.gz.asc

#ENV XDG_RUNTIME_DIR=/run/user/1000

ENTRYPOINT [ "/entrypoint.sh" ]
