# Microservices Demo (MSD) - Docker Swarm Configuration
In this tutorial we will extend the Microservices Demo (MSD) configuration and setup for a Docker Swarm environment. The same pre-requisites are required 

*       [Configuration](#configuration) - Configuration and infrastructure setup
*       [Bootstrap](#bootstrap) - Bootstrapping the Micosservices Demo (MSD) stack and services
*       [Consumption](#consumption) - Consume the sample Beers service via CLI

[Bonus section](#bonus)

*       [IoT Blinkt](#iot_blinkt) - Integrating an [IoT Blinkt API](https://github.com/phriscage/iot_blinkt) for some LED action!


## <a name="prerequisites"></a>Prerequisites:

*       [Docker](https://www.docker.com) basic knowledge
*       [Docker Swarm](ttps://docs.docker.com/engine/swarm) basic knowledge
*	[Docker Stack]((https://docs.docker.com/engine/swarm/stack-deploy/) basic knowledge
*       Docker environment running
*       Download this [repo](https://github.com/phriscage/ca_ms_demo)


### <a name="configuration"></a>Configuration:

Docker Swarm involves nodes, services, and tasks. A node is an Docker host that is running the Docker daemon andpart of a group of nodes or swarm. A service is the definition of tasks that will be execute on nodes in the swarm. The services are the application context that is definedin your Dcoker Compose. Docker Stack provides a command to deploy services from your [docker-compose.yml](docker-compose.yml) to a swarm. Docker stack does not source environment variables from [.env](.env) like Docker Compose. You will need to source them first, then [.custom.env](.custom.env), then *docker stack deploy* to get the services started.

Docker Swarm for MAC has some issues with the overlay networking and multiple nodes are not supported, [issue](https://github.com/docker/for-mac/issues/67). You can setup a single-node Docker Swarm cluster with the MAC, but for now, we will use Docker Machine to provision a boot2docker image. in Virtual Box or other IaaS providers so below is how to get VirtualBox setup. _--virtualbox-host-dns-resolver=true_ is required if not using Docker DNS for MAS HOSTNAME environment variables or localhost 

Virtual Box deployment:

Create boot2docker image:

	docker-machine create --driver=virtualbox --virtualbox-memory=8192 --virtualbox-cpu-count=4 --virtualbox-host-dns-resolver=true master.e2e.caworld.local

Stop machine:

	docker-machine stop master.e2e.caworld.local

Configure bridge port:

Open VBox VM settings, add Bridge port: select interface (Wifi, etc.), promiscious: allow-all, enable cable attached. This can be accomplished with VBoxManage but I don't know the commands yet...

__Confgiure port forwarding:__ # not needed if bridge port enabled

Open VBox VM settings, and select the NAT interface. Add Port forwarding for the following Swarm ports. This can be accomplished with VBoxManage but I don't know the commands yet...

	Swarm 2377 TCP, TCP, 0.0.0.0, 2377, , 2377
	Swarm 4789 UDP, UDP, 0.0.0.0, 4789, , 4789
	Swarm 7946 TCP, TCP, 0.0.0.0, 7946, , 7946
	Swarm 7946 UDP, UDP, 0.0.0.0, 7946, , 7946

Start machine:

	docker-machine start master.e2e.caworld.local

Set environment:

	eval $(docker-machine env master.e2e.caworld.local)

Initialize the Swarm:

We need to utilize a reachable IP address from the worker nodes if the VB IP is not public. My worker devices are on the same Wifi network as en0 so the VM bridged port should be in the same subnet. `docker-machine ssh master.e2e.caworld.local ifconfig eth1` _--advertise-addr_ Typically this is *eth1* for the bridged network:

	docker swarm init --advertise-addr=eth1


### <a name="bootstrap"></a>Bootstrap:

You will need to run *stack deploy* with each _docker-compose.yml_ files if the [Makefile](Makefile) does not have the options available yet. 

Export variables into current session:

	export $(grep -v "^#" .env); source .custom.env; 

Core services:

	docker stack deploy -c docker-compose.yml msd

Beer services:

	docker stack deploy -c docker-compose.beers.yml msd


Now check that all services are running and replicas are correct

	docker stack ls
	docker stack ps msd

	docker service ls


### <a name="consumption"></a>Consumption:

Let's use the client credentials grant to consume the service via curl.

Generate OAuth access token:

	CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=mas_storage oob' https://mas.docker.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;

	
Consume the Beers service from the MGW:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.docker.local:9443/beers?auth=ca-gateway:1

Consume the Beers service from the MAG:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mas.docker.local:8443/beers?auth=ca-gateway:1



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


### <a name="development"></a>Development:

Unset all variables

	unset $(grep -v "^#" .env | cut -d= -f1)
