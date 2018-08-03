FROM ubuntu:bionic
RUN apt update
RUN apt install rsync
ADD ./rsyncd.conf /etc/rsyncd.conf
CMD [ "rsync --daemon" ]