# Microservices Demo (MSD) - Docker Swarm Configuration for CA World
This is the cheat-sheet to get the CA World 17 demo using *.e2e.caworld.local* as the domain. 

*    [Configuration](#configuration) - Configuration and infrastructure setup (VirtualBox only required one time)
*    [Bootstrap](#bootstrap) - Bootstrapping the Micosservices Demo (MSD) stack and services
*    [Consumption](#consumption) - Consume the sample Beers and IoT services via CLI and iOS app
*    [Clean-Up](#cleanup) - Clean-Up services and restart [Bootstrap](#bootstrap)

All the local DNS names for accessing the product administrative interfaces:

	https://mas.e2e.caworld.local
	https://mgw.e2e.caworld.local:9443/quickstart/1.0/doc
	http://lac.e2e.caworld.local:8080
	http://consul.e2e.caworld.local:8500


### <a name="bootstrap"></a>Bootstrap:
Deploy the core and Beers application

	export $(grep -v "^#" .env); source .custom.caw17.env;

	docker stack deploy -c docker-compose.yml msd

	docker stack deploy -c docker-compose.beers.yml msd

	docker service ls

Deploy the iot_blinkt service (not required if you do not have IoT devices):

        docker stack deploy -c docker-compose.iot_blinkt.yml msd

	docker service ls


### <a name="consume"></a>Consume:
Make sure all services are healthy before trying to consume them. I.E. *replicas* from `docker service ls` should not have any zeros '0'

Get a Access Token:

	CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=mas_storage oob' https://mas.e2e.caworld.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;

Test Beers service:

Consume the Beers service from the MGW:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.e2e.caworld.local:9443/beers?auth=ca-gateway:1

Consume the Beers service from the MAG:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mas.e2e.caworld.local:8443/beers?auth=ca-gateway:1

Test IoT Blinkt service:

Consume the Beers service from the MAG without LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.e2e.caworld.local:8443/beers?blinkt=true'

Consume the Beers service from the MAG w/ LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.e2e.caworld.local:8443/beers?auth=ca-gateway:1&blinkt=true'


Consume the Blinkt service directly:

	curl -k -4 -i -X POST -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.e2e.caworld.local:8443/iot/blinkts/random?delay=100'


Consume the Blinkt service in a loop:

	while ((1)); do curl -k -4 -i -X POST -i -H "Authorization: Bearer $ACCESS_TOKEN" "https://mas.e2e.caworld.local:8443/iot/blinkts/random?delay=10"; echo; done



### <a name="configuration"></a>Configuration:
If the custom certs for *.e2e.caworld.local* have not been created in the (config/certs) directory, created them below:

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/mgw.e2e.caworld.local.key -subj "/CN=mgw.e2e.caworld.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:mgw.e2e.caworld.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/mgw.e2e.caworld.local.cert.pem

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/mas.e2e.caworld.local.key -subj "/CN=mas.e2e.caworld.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:mas.e2e.caworld.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/mas.e2e.caworld.local.cert.pem

	openssl pkcs12 -export -clcerts -in config/certs/mas.e2e.caworld.local.cert.pem -inkey config/certs/mas.e2e.caworld.local.key -out config/certs/mas.e2e.caworld.local.cert.p12

	openssl pkcs12 -export -clcerts -in config/certs/mgw.e2e.caworld.local.cert.pem -inkey config/certs/mgw.e2e.caworld.local.key -out config/certs/mgw.e2e.caworld.local.cert.p12


Create a [.custom.caw17.env](.custom.caw17.env) from [.custom.env](.custom.env) with new certificate and environment hostnames. I.E:

```
## Export some application specific environment variables
# license
export SSG_LICENSE=$(gzip -c config/CA_GW_9.xml | base64)
export MGW_LICENSE=$(gzip -c config/CA_MGW_9.xml | base64)
# certificates
export MGW_SSL_KEY_B64="$(cat config/certs/mgw.e2e.caworld.local.cert.p12 | base64)"
export MGW_SSL_KEY_PASS=password
export MGW_SSL_PUBLIC_CERT_B64="$(cat config/certs/mgw.e2e.caworld.local.cert.pem | base64)"
export MAS_SSL_KEY_B64="$(cat config/certs/mas.e2e.caworld.local.cert.p12 | base64)"
export MAS_SSL_KEY_PASS=password
export MAS_SSL_PUBLIC_CERT_B64="$(cat config/certs/mas.e2e.caworld.local.cert.pem | base64)"

# MAS/MAG/OTK
export MAS_HOSTNAME=mas.e2e.caworld.local
export MGW_HOSTNAME=mgw.e2e.caworld.local
export MDC_HOSTNAME=${MAS_HOSTNAME}
export OTK_HOSTNAME=${MAS_HOSTNAME}
export BUNDLE_TEMPLATE_HOSTNAME=${MAS_HOSTNAME}
export BUNDLE_TEMPLATE_OTK_HOSTNAME=${MAS_HOSTNAME}
export BUNDLE_TEMPLATE_DEV_CONSOLE_CALLBACK=https://${MAS_HOSTNAME}:443
# The base64 encoded version of $MAS_HOSTNAME
export BUNDLE_TEMPLATE_HOSTNAME_ENCODED="$(echo -n ${MAS_HOSTNAME} | base64)"
# This is the base64 encoded version of http://$MAS_HOSTNAME
export BUNDLE_TEMPLATE_PROTOCOL_HOSTNAME_ENCODED="$(echo -n http://${MAS_HOSTNAME} | base64)"
export DATABASE_HOST=mysqldb
export DATABASE_PORT=3306
export DATABASE_USER=db_admin
export DATABASE_USER_PASSWORD=UTWtziFHF0xgng==
```

Create new Virtual Box machine with the name *mas.e2e*

	docker-machine create --driver=virtualbox --virtualbox-memory=8192 --virtualbox-cpu-count=4 --virtualbox-host-dns-resolver=true mas.e2e

	docker-machine stop mas.e2e

Enable the bridge interface for a new network adapter in the Virtual Box machine: 
Open VirtualBox MAnager. Click Settings -> Network and create a new *Adpater 3". Attach To: *Bridged Adapter*, Name: *Wifi or hard-wired*. Advanced Promiscuous Mode: *Allow All* and enable *Cable Connected*

Start the Virtual Box machine

	docker-machine start mas.e2e

Update local /etc/hosts entry if domain controller is not *.caworld.local*

Set the environment variables and initialize the Docker Swarm:

	eval $(docker-machine env mas.e2e)

	docker swarm init --advertise-addr=eth1

	docker node ls


### Configure the IoT devices:
You do not have to configure IoT devices if the devices are not available. 

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

Check that all IoT workers show up as nodes:

	docker node ls


### <a name="cleanup"></a>Clean-Up:
Clean all services

	docker stack rm msd
	docker service ls


### Troubleshoting:

If you get a 401 from LAC (should be 404/403), then run the update to load the json config

	```
	{
	  "statusCode": 401,
	  "errorCode": 4012,
	  "errorMessage": "Auth Token cannot be accepted: Project not found:data"
	}
	```

	docker service update msd_lac --force
	docker service update msd_lac_ui --force

