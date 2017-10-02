# Docker Swarm - Microservices Demo (MSD): Microservice creation, discovery, consumption, and enforcement

## Setup
Docker stack does not source environment variables from .env like docker-compose. You will need to source them first, then .custom.env, then *stack deploy* to get the services started.

### Initialize the Swarm 

	docker swarm init

### Start the deployment

	export $(cut -d= -f1 .env | grep -v "^#"); 
	source .custom.env; 
	docker stack deploy -c docker-compose.yml msd
