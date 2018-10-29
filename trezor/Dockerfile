FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y apt-utils systemd
# so scripts won't ask for interactive input.
ENV DEBIAN_FRONTEND=noninteractive

# Currently using https://github.com/romanz/trezor-agent
# https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
RUN apt-get install -y python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev
RUN apt-get install -y wait-for-it openssh-client git tor usbutils curl gnupg2

# 2. Install the TREZOR agent
RUN pip3 install Cython hidapi
RUN pip3 install trezor_agent

RUN mkdir -p /tmp/bcm
WORKDIR /tmp/bcm

# set the GNUPGHOME variable which is used by trezor-agent
ENV GNUPGHOME=/root/.gnupg/trezor

WORKDIR /gitrepo

# RUN mkdir -p /root/.config/systemd/user
# COPY ./trezor-gpg-agent.service /root/.config/systemd/user/trezor-gpg-agent.service 
# COPY ./trezor-gpg-agent.socket /root/.config/systemd/user/trezor-gpg-agent.socket 

# run this script to quickly configure and commit and sign a repo
RUN mkdir /bcm_scripts
COPY ./container_scripts/commit_sign_git_repo.sh /bcm_scripts/commit_sign_git_repo.sh
RUN chmod +x /bcm_scripts/commit_sign_git_repo.sh

# run this script to quickly configure and commit and sign a repo
COPY ./container_scripts/git_push.sh /bcm_scripts/git_push.sh
RUN chmod +x /bcm_scripts/git_push.sh

# run this script to quickly configure and commit and sign a repo
COPY ./container_scripts/trezor_agent_entrypoint.sh /bcm_scripts/trezor_agent_entrypoint.sh
RUN chmod +x /bcm_scripts/trezor_agent_entrypoint.sh

ENTRYPOINT [ "/bcm_scripts/trezor_agent_entrypoint.sh" ]
