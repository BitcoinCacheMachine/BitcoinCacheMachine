FROM golang:latest
#1.10.3

# lnd p2p, grpc server
EXPOSE 9735 10009

ENV GODEBUG netdns=cgo

RUN apt update
RUN apt install curl jq wait-for-it -y
RUN go get -u github.com/golang/dep/cmd/dep

RUN git clone https://github.com/lightningnetwork/lnd $GOPATH/src/github.com/lightningnetwork/lnd
WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd
RUN dep ensure
RUN go install . ./cmd/...

RUN mkdir -p /data && mkdir -p /var/logs/lnd

# where lnd data goes
VOLUME /root/.lnd

# certificate data used by lnd and remote grpc services
VOLUME /config

# macaroons for grpc access
VOLUME /macaroons

# logs, duh
VOLUME /logs

WORKDIR /root/.lnd

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]