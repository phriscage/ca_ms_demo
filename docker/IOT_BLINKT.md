# Microservices Demo (MSD) - IoT Blinkt Configuration
In this tutorial we will extend the Microservices Demo (MSD) configuration and setup for a IoT Blinkt Raspberry Pi device. The same pre-requisites are required 

*	[README](README.md) - Setup the MSD
*	[SWARM_SETUP](SWARM_SETUP.md) - Configure MSD for Docker Swarm
*	[Consumption](#consumption) - Consume the sample Beers service with IoT Blinkt via CLI

## <a name="prerequisites"></a>Prerequisites:

*	[IoT Blinkt API](https://github.com/phriscage/iot_blinkt)

### <a name="iot_blinkt"></a>IoT Blinkt Bootstrap:

The IoT Blinkt service needs to run on an IoT worker node which is a Raspberry Pi device with a Blinkt GPIO interface connected. Each Raspberry Pi needs to be added to the Docker swarm before the service can be created. 

Create a Swarm token environment variable

	SWARM_TOKEN=$(docker swarm join-token -q worker)

Create a Swarm master IP address environment variable

	SWARM_MASTER=$(docker info | grep -w 'Node Address' | awk '{print $3}')

Loop through the IoT worker hostnames via the IOT_WORKERS environment variable and execute the swarm join command with SWARM_TOKEN and SWARM_MASTER variables defined above.

	IOT_WORKERS="thing2.local thing3.local";
	IOT_USERNAME="pi";
	for host in $IOT_WORKERS; do
		ssh $IOT_USERNAME@$host "docker swarm leave; docker swarm join --token $SWARM_TOKEN $SWARM_MASTER:2377"
	done

Deploy the iot_blinkt service:

        docker stack deploy -c docker-compose.iot_blinkt.yml msd


### <a name="consumption"></a>Consumption:

Let's use the client credentials grant to consume the service via curl.

Generate OAuth access token:

        CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=mas_storage oob' https://mas.docker.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;


Consume the Beers service from the MAG without LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/beers?blinkt=true'

Consume the Beers service from the MAG w/ LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/beers?auth=ca-gateway:1&blinkt=true'


Consume the Blinkt service directly:

	curl -k -4 -i -X POST -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/iot/blinkts/random?delay=100'


Consume the Blinkt service in a loop:

	while ((1)); do curl -k -4 -i -X POST -i -H "Authorization: Bearer $ACCESS_TOKEN" "https://mas.docker.local:8443/iot/blinkts/random?delay=10"; echo; done
