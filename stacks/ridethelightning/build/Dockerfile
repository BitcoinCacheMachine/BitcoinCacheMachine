FROM node:10-alpine

RUN apk add --no-cache tini git
RUN git clone https://github.com/ShahanaFarooqui/RTL /root/rtl
WORKDIR /root/rtl
RUN git checkout master
#tags/v0.3.0
#

RUN mkdir /RTL
RUN cp package.json /RTL/package.json
RUN cp package-lock.json /RTL/package-lock.json

WORKDIR /RTL

# Install dependencies
RUN npm install

RUN cp -a /root/rtl/. /RTL/

RUN rm -rf /root/rtl

EXPOSE 3000

# Specify the start command and entrypoint as the lnd daemon.
#ADD ./entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh

#ENTRYPOINT [ "/entrypoint.sh" ]
ENTRYPOINT ["/sbin/tini", "-g", "--"]

CMD ["node", "rtl"]