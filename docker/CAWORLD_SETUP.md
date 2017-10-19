# Microservices Demo (MSD) - Docker Swarm Configuration for CA World

Using *.e2e.caworld.local* as the domain

	https://mas.e2e.caworld.local
	https://mgw.e2e.caworld.local:9443/quickstart/1.0/doc
	http://lac.e2e.caworld.local:8080
	http://consul.e2e.caworld.local:8500

### Setup:

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/mgw.e2e.caworld.local.key -subj "/CN=mgw.e2e.caworld.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:mgw.e2e.caworld.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/mgw.e2e.caworld.local.cert.pem

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/mas.e2e.caworld.local.key -subj "/CN=mas.e2e.caworld.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:mas.e2e.caworld.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/mas.e2e.caworld.local.cert.pem

	openssl pkcs12 -export -clcerts -in config/certs/mas.e2e.caworld.local.cert.pem -inkey config/certs/mas.e2e.caworld.local.key -out config/certs/mas.e2e.caworld.local.cert.p12

	openssl pkcs12 -export -clcerts -in config/certs/mgw.e2e.caworld.local.cert.pem -inkey config/certs/mgw.e2e.caworld.local.key -out config/certs/mgw.e2e.caworld.local.cert.p12

Modify [.custom.caw17.env](.custom.caw17.env) with new hostnames
	
	docker-machine create --driver=virtualbox --virtualbox-memory=8192 --virtualbox-cpu-count=4 --virtualbox-host-dns-resolver=true mas.e2e

	docker-machine stop mas.e2e

Enable the bridge interface

	docker-machine start mas.e2e

Update local /etc/hosts entry if domain controller is not *.caworld.local*

	eval $(docker-machine env mas.e2e)

	docker swarm init --advertise-addr=eth1

	docker node ls

### Deploy:

	export $(grep -v "^#" .env); source .custom.caw17.env;

	docker stack deploy -c docker-compose.4.0.00-CR01.yml msd

	docker stack deploy -c docker-compose.beers.yml msd

	docker service ls


### Test:

	CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=mas_storage oob' https://mas.e2e.caworld.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;

Consume the Beers service from the MGW:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.e2e.caworld.local:9443/beers?auth=ca-gateway:1

Consume the Beers service from the MAG:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mas.e2e.caworld.local:8443/beers?auth=ca-gateway:1


### IoT Deploy:

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

Consume the Beers service from the MAG without LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/beers?blinkt=true'

Consume the Beers service from the MAG w/ LAC auth:

        curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/beers?auth=ca-gateway:1&blinkt=true'


Consume the Blinkt service directly:

	curl -k -4 -i -X POST -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mas.docker.local:8443/iot/blinkts/random?delay=100'


Consume the Blinkt service in a loop:

	while ((1)); do curl -k -4 -i -X POST -i -H "Authorization: Bearer $ACCESS_TOKEN" "https://mas.docker.local:8443/iot/blinkts/random?delay=10"; done


### Troubleshoting:

If you get a 401 from LAC (should be 404/403), then run the update to load the json config

	```
	{
	  "statusCode": 401,
	  "errorCode": 4012,
	  "errorMessage": "Auth Token cannot be accepted: Project not found:data"
	}
	```

	docker service update msd_lac mas_lac_ui --force

