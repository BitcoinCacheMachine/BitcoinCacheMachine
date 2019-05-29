FROM golang:alpine as builder

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

# Install dependencies and build the binaries.
RUN apk add --no-cache --update alpine-sdk git make gcc
RUN git clone https://github.com/lightningnetwork/lnd /go/src/github.com/lightningnetwork/lnd
WORKDIR /go/src/github.com/lightningnetwork/lnd
RUN git checkout master
RUN make
RUN make install

# tags="signrpc walletrpc chainrpc invoicesrpc"
#tags on make install is required by lightning loop

# this is the final image
FROM alpine as final

# Define a root volume for data persistence.
VOLUME /root/.lnd

# Add bash and ca-certs, for quality of life and SSL-related reasons.
RUN apk --no-cache add bash ca-certificates

# Copy the binaries from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Expose lnd ports (p2p, rpc).
EXPOSE 9735 10009

# Specify the start command and entrypoint as the lnd daemon.
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /root/.lnd

ENTRYPOINT ["/entrypoint.sh"]



# FROM golang:latest
# #1.10.3

# # lnd p2p, grpc server
# EXPOSE 9735 10009

# ENV GODEBUG netdns=cgo

# RUN apt-get update
# RUN apt-get install -y --no-install-recommends curl jq wait-for-it
# RUN go get -u github.com/golang/dep/cmd/dep

# RUN git clone https://github.com/lightningnetwork/lnd $GOPATH/src/github.com/lightningnetwork/lnd
# WORKDIR $GOPATH/src/github.com/lightningnetwork/lnd
# RUN git checkout v0.5.2-beta
# RUN dep init
# RUN dep ensure
# RUN go install . ./cmd/...

# RUN mkdir -p /data && mkdir -p /var/logs/lnd

# # where lnd data goes
# VOLUME /root/.lnd

# # certificate data used by lnd and remote grpc services
# VOLUME /config

# # macaroons for grpc access
# VOLUME /macaroons

# # logs, duh
# VOLUME /logs

# WORKDIR /root/.lnd

# ADD ./entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]