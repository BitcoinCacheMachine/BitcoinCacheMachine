FROM ubuntu:bionic

ENV http_proxy=http://squid.bcmnet:3128 \
    https_proxy=http://squid.bcmnet:3128

RUN apt-get update -o Acquire::ForceIPv4=true && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools \
    openssh-server \
    rsync \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Prevent the creation of ~/.cache/motd.legal-displayed
RUN sed 's@session\s*optional\s*pam_motd.so.*@#&@g' -i /etc/pam.d/sshd

RUN echo 'AuthorizedKeysFile /etc/ssh/%u/authorized_keys' >> /etc/ssh/sshd_config

RUN groupadd -g 1000 rsync \
  && useradd -d /rsync -u 1000 -g 1000 -m -s /bin/bash rsync

RUN mkdir -p /etc/ssh/rsync \
  && chown rsync.rsync /etc/ssh/rsync

VOLUME /rsync

EXPOSE 22

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]