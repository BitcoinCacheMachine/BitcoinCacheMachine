FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y apt-utils
# so scripts won't ask for interactive input.
ENV DEBIAN_FRONTEND=noninteractive

# Currently using https://github.com/romanz/trezor-agent
# https://github.com/romanz/trezor-agent/blob/master/doc/INSTALL.md
RUN apt-get install -y python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev

############3 GPG INSTALL INSTRUCTIONS
# needed because we're going to use PGP operations on the trezor
# instructions from https://gist.github.com/vt0r/a2f8c0bcb1400131ff51

RUN mkdir -p /tmp/bcm
WORKDIR /tmp/bcm


####### END GPG INSTALL INSTRUCTIONS

# refactor later, for trezor USB interaction
RUN apt-get install -y git tor usbutils 
RUN apt-get install -y curl gnupg2

# #This script installs all the necessary gnupg 2.2.x software.
# COPY ./gnupg_install.sh /gnupg_install.sh
# RUN chmod +x /gnupg_install.sh
# RUN /gnupg_install.sh


# 2. Install the TREZOR agent
RUN pip3 install Cython hidapi
RUN pip3 install trezor_agent

#COPY ./agent.conf ~/.ssh/agent.conf
# this trezor versio
ENV GNUPGHOME=/root/.gnupg/trezor

WORKDIR /gitrepo



# run this script to quickly configure and commit and sign a repo
COPY ./commit_sign_git_repo.sh /commit_sign_git_repo.sh
RUN chmod +x /commit_sign_git_repo.sh

# run this script to quickly configure and commit and sign a repo
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

RUN apt-get install wait-for-it