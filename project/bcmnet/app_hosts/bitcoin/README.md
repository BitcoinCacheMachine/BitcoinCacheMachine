# bcm_lxd_bitcoin
The LXD Stack for Bitcoin Cache Machine.


 Individual RPC interfaces (e.g., lnd gRPC interface) may be exposed at unique TOR onion sites which allows mobile apps to securely connect to infrastructure. Like manager lxc containers, `bitcoin` uses a `cachestack` (either local or a networked standalone `cachestack`) to pull docker images. The [docker-ce]("https://docs.docker.com/install/#next-release") daemon on `bitcoin` is configured to log via GELF to a logstash-based GELF listener on `manager1`; logs are stored in Kafka. PLANNED - log messages will be converted and stored in [AVRO](https://www.confluent.io/blog/avro-kafka-data/) using [Kafka Schema Registry]("https://github.com/confluentinc/schema-registry"). PLANNED - implement kafka schema-evolution.