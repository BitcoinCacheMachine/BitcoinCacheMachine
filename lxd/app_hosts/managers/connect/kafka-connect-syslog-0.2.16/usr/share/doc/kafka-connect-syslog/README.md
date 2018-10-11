## Introduction

This connector provides support for receiving messages via syslog.

## Important

The 0.2 release breaks compatibility with the existing schema. 

  
# Configuration

## SSLTCPSyslogSourceConnector

Connector is used to receive syslog messages via SSL over TCP.

```properties
name=connector1
tasks.max=1
connector.class=com.github.jcustenborder.kafka.connect.syslog.SSLTCPSyslogSourceConnector

# Set these required values
syslog.keystore.password=
syslog.keystore=
syslog.truststore=
syslog.truststore.password=
kafka.topic=
syslog.port=
```

| Name                               | Description                                                                                                                   | Type     | Default | Valid Values | Importance |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|----------|---------|--------------|------------|
| kafka.topic                        | Kafka topic to write syslog data to.                                                                                          | string   |         |              | high       |
| syslog.keystore                    | Path to the keystore containing the ssl certificate for this host.                                                            | string   |         |              | high       |
| syslog.keystore.password           | Password for the keystore.                                                                                                    | password |         |              | high       |
| syslog.port                        | Port to listen on.                                                                                                            | int      |         |              | high       |
| syslog.truststore                  | Path to the truststore containing the ssl certificate for this host.                                                          | string   |         |              | high       |
| syslog.truststore.password         | Password for the truststore.                                                                                                  | password |         |              | high       |
| syslog.host                        | Hostname to listen on.                                                                                                        | string   | null    |              | high       |
| backoff.ms                         | Number of milliseconds to sleep when no data is returned.                                                                     | int      | 100     | [50,...]     | low        |
| batch.size                         | The number of records to pull off of the queue at once.                                                                       | int      | 5000    |              | low        |
| syslog.backlog                     | Number of connections to allow in backlog.                                                                                    | int      | 50      | [1,...]      | low        |
| syslog.charset                     | Character set for syslog messages.                                                                                            | string   | UTF-8   |              | low        |
| syslog.max.active.sockets          | Maximum active sockets                                                                                                        | int      | 0       |              | low        |
| syslog.max.active.sockets.behavior | Maximum active sockets                                                                                                        | int      | 0       |              | low        |
| syslog.reverse.dns.cache.ms        | The amount of time to cache the reverse lookup values from DNS.                                                               | long     | 60000   |              | low        |
| syslog.reverse.dns.remote.ip       | Flag to determine if the ip address of the remote sender should be resolved. If set to false the hostname value will be null. | boolean  | false   |              | low        |
| syslog.shutdown.wait               | The amount of time in milliseconds to wait for messages when shutting down the server.                                        | long     | 500     |              | low        |
| syslog.structured.data             | Flag to determine if structured data should be used.                                                                          | boolean  | false   |              | low        |
| syslog.timeout                     | Number of milliseconds before a timing out the connection.                                                                    | int      | 0       |              | low        |

## TCPSyslogSourceConnector

Connector is used to receive syslog messages over TCP.

```properties
name=connector1
tasks.max=1
connector.class=com.github.jcustenborder.kafka.connect.syslog.TCPSyslogSourceConnector

# Set these required values
kafka.topic=
syslog.port=
```

| Name                               | Description                                                                                                                   | Type    | Default | Valid Values | Importance |
|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------|---------|---------|--------------|------------|
| kafka.topic                        | Kafka topic to write syslog data to.                                                                                          | string  |         |              | high       |
| syslog.port                        | Port to listen on.                                                                                                            | int     |         |              | high       |
| syslog.host                        | Hostname to listen on.                                                                                                        | string  | null    |              | high       |
| backoff.ms                         | Number of milliseconds to sleep when no data is returned.                                                                     | int     | 100     | [50,...]     | low        |
| batch.size                         | The number of records to pull off of the queue at once.                                                                       | int     | 5000    |              | low        |
| syslog.backlog                     | Number of connections to allow in backlog.                                                                                    | int     | 50      | [1,...]      | low        |
| syslog.charset                     | Character set for syslog messages.                                                                                            | string  | UTF-8   |              | low        |
| syslog.max.active.sockets          | Maximum active sockets                                                                                                        | int     | 0       |              | low        |
| syslog.max.active.sockets.behavior | Maximum active sockets                                                                                                        | int     | 0       |              | low        |
| syslog.reverse.dns.cache.ms        | The amount of time to cache the reverse lookup values from DNS.                                                               | long    | 60000   |              | low        |
| syslog.reverse.dns.remote.ip       | Flag to determine if the ip address of the remote sender should be resolved. If set to false the hostname value will be null. | boolean | false   |              | low        |
| syslog.shutdown.wait               | The amount of time in milliseconds to wait for messages when shutting down the server.                                        | long    | 500     |              | low        |
| syslog.structured.data             | Flag to determine if structured data should be used.                                                                          | boolean | false   |              | low        |
| syslog.timeout                     | Number of milliseconds before a timing out the connection.                                                                    | int     | 0       |              | low        |

## UDPSyslogSourceConnector

Connector is used to receive syslog messages over UDP.

```properties
name=connector1
tasks.max=1
connector.class=com.github.jcustenborder.kafka.connect.syslog.UDPSyslogSourceConnector

# Set these required values
kafka.topic=
syslog.port=
```

| Name                         | Description                                                                                                                   | Type    | Default | Valid Values | Importance |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------|---------|---------|--------------|------------|
| kafka.topic                  | Kafka topic to write syslog data to.                                                                                          | string  |         |              | high       |
| syslog.port                  | Port to listen on.                                                                                                            | int     |         |              | high       |
| syslog.host                  | Hostname to listen on.                                                                                                        | string  | null    |              | high       |
| backoff.ms                   | Number of milliseconds to sleep when no data is returned.                                                                     | int     | 100     | [50,...]     | low        |
| batch.size                   | The number of records to pull off of the queue at once.                                                                       | int     | 5000    |              | low        |
| syslog.charset               | Character set for syslog messages.                                                                                            | string  | UTF-8   |              | low        |
| syslog.reverse.dns.cache.ms  | The amount of time to cache the reverse lookup values from DNS.                                                               | long    | 60000   |              | low        |
| syslog.reverse.dns.remote.ip | Flag to determine if the ip address of the remote sender should be resolved. If set to false the hostname value will be null. | boolean | false   |              | low        |
| syslog.shutdown.wait         | The amount of time in milliseconds to wait for messages when shutting down the server.                                        | long    | 500     |              | low        |
| syslog.structured.data       | Flag to determine if structured data should be used.                                                                          | boolean | false   |              | low        |


# Schemas

## com.github.jcustenborder.kafka.connect.syslog.SyslogValue

This schema represents a syslog message that is written to Kafka.

| Name           | Optional | Schema                                                                                                | Default Value | Documentation                                                                                |
|----------------|----------|-------------------------------------------------------------------------------------------------------|---------------|----------------------------------------------------------------------------------------------|
| date           | true     | [Timestamp](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Timestamp.html)       |               | The timestamp of the message.                                                                |
| facility       | true     | [Int32](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#INT32)   |               | The facility of the message.                                                                 |
| host           | true     | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The host of the message.                                                                     |
| level          | true     | [Int32](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#INT32)   |               | The level of the syslog message as defined by [rfc5424](https://tools.ietf.org/html/rfc5424) |
| message        | true     | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The text for the message.                                                                    |
| charset        | true     | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The character set of the message.                                                            |
| remote_address | true     | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The ip address of the host that sent the syslog message.                                     |
| hostname       | true     | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The reverse DNS of the `remote_address` field.                                               |

## com.github.jcustenborder.kafka.connect.syslog.SyslogKey

This schema represents the key that is written to Kafka for syslog data. This will ensure that all data for a host ends up in the same partition.

| Name           | Optional | Schema                                                                                                | Default Value | Documentation                                            |
|----------------|----------|-------------------------------------------------------------------------------------------------------|---------------|----------------------------------------------------------|
| remote_address | false    | [String](https://kafka.apache.org/0102/javadoc/org/apache/kafka/connect/data/Schema.Type.html#STRING) |               | The ip address of the host that sent the syslog message. |


# Development 

## Debugging

```bash
./bin/debug.sh
```

## Suspend waiting for a debugger.

```bash
export SUSPEND='Y'
./bin/debug.sh
```