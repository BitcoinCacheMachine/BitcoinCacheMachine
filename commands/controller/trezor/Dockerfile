ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# install instructions:  https://github.com/romanz/trezor-agent
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --fix-missing -y apt-utils git pass python3-pip python3-dev python3-tk libusb-1.0-0-dev libudev-dev wait-for-it openssh-client git tor usbutils curl gnupg2 && \
    pip3 install Cython hidapi && \
    pip3 install trezor_agent

RUN git clone https://github.com/romanz/trezor-agent /trezor-agent
WORKDIR /trezor-agent
RUN git checkout latest-trezorlib
RUN pip3 install -e /trezor-agent/agents/trezor

RUN groupadd -r -g 1000 user 
RUN adduser --disabled-login --system --shell /bin/false --uid 1000 --gid 1000 user

VOLUME /home/user/gitrepo

# run this script to quickly configure and commit and sign a repo
RUN mkdir /home/user/bcmscripts
ADD ./scripts/commit_sign_git_repo.sh /home/user/bcmscripts/commit_sign_git_repo.sh
RUN chmod 0755 /home/user/bcmscripts/commit_sign_git_repo.sh

# run this script to quickly configure and tag and sign a repo
ADD ./scripts/tag_sign_git_repo.sh /home/user/bcmscripts/tag_sign_git_repo.sh
RUN chmod 0755 /home/user/bcmscripts/tag_sign_git_repo.sh

# run this script to quickly configure verify branches and merge them with a signature
ADD ./scripts/merge_sign_git_repo.sh /home/user/bcmscripts/merge_sign_git_repo.sh
RUN chmod 0755 /home/user/bcmscripts/merge_sign_git_repo.sh

# run this script to quickly configure and commit and sign a repo
ADD ./scripts/docker-entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENV GNUPGHOME=/home/user/.gnupg/trezor

USER user

WORKDIR /home/user/gitrepo
