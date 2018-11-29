#!/bin/bash


# list topics
lxc exec manager1 -- curl -s "http://localhost:8082/topics" | jq


# get info on a topic
lxc exec manager1 -- curl -s "http://localhost:8082/topics/syslog" | jq



# create a consumer for the avro data
lxc exec manager1 -- curl -X POST  -H "Content-Type: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/dev_syslog_consumer


lxc exec manager1 -- curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["syslog"]}' http://localhost:8082/consumers/dev_syslog_consumer/instances/my_consumer_instance/subscription


lxc exec manager1 -- curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/records




  [{"key":null,"value":{"name":"testUser"},"partition":0,"offset":1,"topic":"avrotest"}]







###################################################################################3
# execute CURL statements as if it's running on localhost.
#curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d @/app/TCPSyslogSourceConnector.json localhost:8083/connectors





# Create a consumer for Avro data, starting at the beginning of the topic's
# log and subscribe to a topic. Then consume some data from a topic, which is decoded, translated to
# JSON, and included in the response. The schema used for deserialization is
# fetched automatically from the schema registry. Finally, clean up.
lxc exec manager1 -- curl -X POST  -H "Content-Type: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "avro", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/my_avro_consumer

# produce a message with JSON data to topic jsontest
lxc exec manager1 -- curl -X POST -H "Content-Type: application/vnd.kafka.json.v2+json" --data '{"records":[{"value":{"name": "testUser"}}]}' "http://localhost:8082/topics/jsontest"

# create a consumer called 'my_consumer_instance' 
lxc exec manager1 -- curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" -H "Accept: application/vnd.kafka.v2+json" --data '{"name": "my_consumer_instance", "format": "json", "auto.offset.reset": "earliest"}' http://localhost:8082/consumers/my_json_consumer

# subscribe the above consumer to the jsontest topic
lxc exec manager1 -- curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["jsontest"]}' http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/subscription

# next consume the data from a topic
lxc exec manager1 -- curl -X GET -H "Accept: application/vnd.kafka.json.v2+json" http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance/records

# close the consumer
lxc exec manager1 -- curl -X DELETE -H "Accept: application/vnd.kafka.v2+json" http://localhost:8082/consumers/my_json_consumer/instances/my_consumer_instance








#output
# {"instance_id":"my_consumer_instance","base_uri":"http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance"}

# create a topic called AvroTest
lxc exec manager1 -- curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["syslog"]}' http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/subscription



lxc exec manager1 -- curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/records



{"instance_id":"my_consumer_instance","base_uri":"http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance"}


# Get 
lxc exec manager1 -- curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance/records


lxc exec manager1 -- curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" http://localhost:8082/consumers/my_avro_consumer/instances/my_consumer_instance