FROM rust:1.33.0-slim

RUN apt-get update
RUN apt-get install -y clang cmake 
RUN apt-get install -y libsnappy-dev
RUN apt-get install -y git

# RUN adduser --disabled-login --system --shell /bin/false --uid 1000 user

# USER user
# WORKDIR /home/user

RUN git clone https://github.com/romanz/electrs /root/electrs
WORKDIR /root/electrs
RUN git checkout tags/v0.5.0

RUN cargo build --release
RUN cargo install --path .

# Electrum RPC
EXPOSE 50001

# Prometheus monitoring
EXPOSE 4224

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


STOPSIGNAL SIGINT
