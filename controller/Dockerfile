ARG BCM_DOCKER_BASE_TAG

FROM ubuntu:${BCM_DOCKER_BASE_TAG}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils git pass

# Currently using https://github.com/romanz/trezor-agent https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
RUN apt-get install -y python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev --fix-missing
RUN apt-get install -y wait-for-it openssh-client git tor usbutils curl gnupg2

# 2. Install the TREZOR agent
RUN pip3 install Cython hidapi
RUN pip3 install trezor_agent

RUN mkdir /tmp/trezor
RUN git clone https://github.com/romanz/trezor-agent /tmp/trezor
WORKDIR /tmp/trezor
RUN git checkout latest-trezorlib
RUN pip3 install -e /tmp/trezor/agents/trezor

WORKDIR /gitrepo

# run this script to quickly configure and commit and sign a repo
RUN mkdir /bcm
ADD ./container_scripts/commit_sign_git_repo.sh /bcm/commit_sign_git_repo.sh
RUN chmod +x /bcm/commit_sign_git_repo.sh

# run this script to quickly configure and commit and sign a repo
ADD ./container_scripts/git_pull.sh /bcm/git_pull.sh
RUN chmod +x /bcm/git_pull.sh

# run this script to quickly configure and commit and sign a repo
ADD ./container_scripts/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY ./51-trezor.rules /etc/udev/rules.d/51-trezor.rules

RUN groupadd -r -g 1000 user 
RUN adduser --disabled-login --system --shell /bin/false --uid 1000 --gid 1000 user

USER user
WORKDIR /home/user

ENV GNUPGHOME=/home/user/.gnupg/trezor
