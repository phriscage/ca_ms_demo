# Microservices Demo (MSD): Microservice creation, discovery, consumption, and enforcement 

This tutorial will cover the following:

*	[Bootstrap](#bootstrap) - Bootstrapping the CA Mobile App Services (MAS), CA Microgateway (MGW), and CA Live API Creator (LAC) in Docker]
*	[Creation](#creation) - How LAC can create a RESTful microservice (MS) from a relational datastore (MySQL)
*	[Security](#security) - How the MGW enforces OAuth security and rate limiting for the MS
*	[Discovery](#discovery) - How the MGW enables programmatic discovery through service registry (Consul) via Quickstart templates
* 	[Consumption](#consumption) - How the MAS provides mobile application MS consumption through developer console and SDKs

[Bonus section](#bonus)

*	[Token Bridge](#token_bridge) - How the MGW provides token bridging from OAuth to JWT
*	[Token Exchange](#token_exchange) - How the MAS provides token exchange for service-to-service AuthN/AuthZ

## <a name="prerequisites"></a>Prerequisites:

*	[Mobile API Gateway](https://docops.ca.com/ca-mobile-api-gateway/4-0/en) basic knowledge
*	[Mobile App Services](https://docops.ca.com/ca-mobile-app-services/1-4/en) basic knowledge
*	[Mobile Developer Console](https://docops.ca.com/ca-mobile-developer-console/1-0/en) basic knowledge
*	[Live API Creator](https://docops.ca.com/ca-live-api-creator/3-2/en) basic knowledge
*	[Docker](https://www.docker.com) basic knowledge
*	[Docker Compose](https://www.docker.com/products/docker-compose) basic knowledge
*	[Consul](https://www.consul.io/) basic knowledge
*	[Apple Xcode](https://developer.apple.com/xcode) basic knowledge
* 	[Docker-MAS README](https://github.com/CAAPIM/Docker-MAS/blob/master/README.md)
*	Docker environment running
*	Download this [repo](https://github.com/phriscage/ca_ms_demo)


### <a name="configuration"></a>Configuration:

Theses steps will setup the environment to showcase the use-cases above. The FQDN references in the tutorial will be **mas.docker.local**, **msgw.docker.local**, **lac.docker.local** for the MAS/OTK, MGW, and LAC UI external services respectively. **consul.docker.local** will be used to reference the Consul UI. The FQDNs point to your Docker Engine IP address so update your local */etc/hosts* file accordingly. *For native Docker on the MAC, this is the loopback IP: **127.0.0.1**.* The FQDNs can be changed to suite your needs, but the coresponding environment variables and x509 certificates should also be changed (see [development](#development))

Default environment variables are in the [.env](.env) file that is automatically read from Docker Compose. Custom environment variables are exported from the Makefile for every *make* command vi the [.custom.env](.custom.env) file. These custom environment variables include application specific hostnames, certificates, and user credentials:

```
## Export some application specific environment variables
# license
export SSG_LICENSE=$(gzip -c config/license.xml | base64)
# certificates
export MGW_SSL_KEY_B64="$(cat config/certs/msgw.cert.p12 | base64)"
export MGW_SSL_KEY_PASS=password
export MGW_SSL_PUBLIC_CERT_B64="$(cat config/certs/msgw.cert.pem | base64)"
export MAS_SSL_KEY_B64="$(cat config/certs/mas.cert.p12 | base64)"
export MAS_SSL_KEY_PASS=password
export MAS_SSL_PUBLIC_CERT_B64="$(cat config/certs/mas.cert.pem | base64)"

# MAS/MAG/OTK
export MAS_HOSTNAME=mas.docker.local
export MDC_HOSTNAME=${MAS_HOSTNAME}
export OTK_HOSTNAME=${MAS_HOSTNAME}
...
```

## <a name="installation"></a>Installation:

### <a name="bootstrap"></a>Bootstrap: 

Start the main application via the **make** command. The default option is the *run-beers* command (docker-compose -f docker-compose.yml -f docker-compose.beers.yml up -d). You can tail the logs in this terminal via *make log-beers* or open a new one (docker-compose -f docker-compose.yml -f docker-compose.beers.yml logs -f)

	make

Once the application is ready, you should be able to login to the MAS developer console, view the MGW Quickstart documentation, LAC interface, and Consul interface. The MAS, MGW, and LAC require and administrator for authentication, username/password: **admin/password** for MAS/MGW and **admin/Password1** for LAC

	https://msgw.docker.local:9443/quickstart/1.0/doc
	https://mas.docker.local
	https://lac.docker.local
	https://consul.docker.local:8500

## <a name="demo examples"></a>Demo examples:

### <a name="creation"></a>Creation:

The LAC interface allows you to create a RESTful API with a few clicks by providing a datasource and credentials. There is already a pre-defined example Beer Data that is loaded when the LAC container starts. The Beer Data LAC MS returns some beer attributes from a MySQL database. You can check out the seeded data with the following command:

	docker-compose -f docker-compose.beers.yml exec mysql_beers  mysql -uroot -proot -e "SELECT * FROM data.beers ORDER BY updated_at DESC LIMIT 10"

You can walk through the functionality of LAC from the [user interface](http://lac.docker.local)


### <a name="discovery"></a>Discovery:

The Quickstart template language provides a JSON syntax language to protect and discover your MS in the MGW. The [Quickstart Beer Data example](files/msgw/quickstart/beer_data.json) is leveraging the MGW's 'RequireOauth2Token' to validate an OAuth Bearer access token with proper scope via the OAuth hub of the MAS/OTK instance. CORS for Cross-Origin Resource Sharing and Ratelimiting are also included to protect the MS. The 'ConsulLookup' integrates with Consul to query the MS service availability and dynamically update routing strategies based off container availability. The Quickstart JSON file is below:

```
{
  "Service": {
    "name": "Beer Data Demo",
    "gatewayUri": "/beers*",
    "httpMethods": [ "get", "post", "delete" ],
    "policy": [
      	{
       	    "Cors" : {}
      	},
	{
	  "RequireOauth2Token": {
	    "scope_required": "no-id-token",
	    "scope_fail": "false",
	    "onetime": "false",
	    "given_access_token": ""
	  }
	},
        {
          "RateLimit" : {
            "maxRequestsPerSecond": 1,
            "hardLimit": true,
            "counterName": "RateLimit-Counter"
      	  }
        },
 	{
       	  "ConsulLookup" : {
            "consul.agentAddr": "http://consul.:8500",
            "pathPrefix": "/rest/default/data/v1/main:beers",
            "routingStrategy": "roundRobin",
            "serviceName": "lac",
            "scheme": "http://"
       	  }
     	},
        {
          "RouteHttp" : {
            "targetUrl" : "${service.baseUrl}",
            "httpMethod" : "${request.http.method}",
	    "preserveRequestPath": true,
	    "useAuthenticationHeader": "jwt"
          }
        }
      ]
    }
}
```
Full list of template options in the [docs](https://msgw.docker.local:9443/quickstart/1.0/doc). The Quickstart payloads can  be provisioned programatically via curl, service registry, etc. or during container instantiation via a configruation managment database and/or continuous integation/deployment systems (CI/CD)*

Check the service exists via *curl* or *browser*

	curl -k -4 -i -u 'admin:password' https://msgw.docker.local:9443/quickstart/1.0/services

Try to access the Beer Data service with Basic Auth (failure)

	curl -k -4 -i -u 'admin:password' https://msgw.docker.local:9443/beers

We need a valid OAuth token to access the protected resource. Let's consume the new MS via a Mobile client. You can also use curl in the [Bonus](#bonus) section below.


### <a name="consumption"></a>Consumption:

Now that the MS is protected by the MGW, let's levage a simple mobile application to consume the MS via OAuth tokens. Navigate to the [MAS Developer Console](https://mas.docker.local) and login with the admin credentials. Create a new application, select the iOS platform, and download the **msso_config.json**. Open the [MicroservicesDemo.xcworkspace](../MicroservicesDemo/MicroservicesDemo.xcworkspace) in Xcode <~ 8.3.x and place the **msso_config.json** file into the project. The *Supporting Files* folder is typically where I drop it. Build the iOS mobile application and run the simluator in iOS <~ 10.x. Login to the mobile application and you can now see the Beers from the Beer data API you created!. 


### <a name="security"></a>Security:

Since we added Rate Limiting in our [Quickstart Beer Data example](files/msgw/quickstart/beer_data.json), you can hit refresh a few times on the Beer list table to trigger the limit. Try adding a new Beer and show the data in the database. Remove the data and refresh. All done. That was easy!


## <a name="bonus"></a>Bonus section:

### <a name="token_bridge"></a>Token Bridge:

The Token Exchange Python service returns some basic host information (hostname, ip_address) and the coresponding request headers. The [Quickstart Token Exchange example](files/msgw/quickstart/token_exchange.json) is leveraging the MGW's 'RequireOauth2Token' to validate an OAuth Bearer access token with the OAuth hub of the MAS/OTK instance. CORS and Ratelimiting are also included to proteect the MS. The Quickstart JSON file is below:

Create the Token Exchange demo service:

	curl -k -4 -i -u 'admin:password' https://msgw.docker.local:9443/quickstart/1.0/services --data @files/msgw/quickstart/token_exchange.json

Check the service exists:

	curl -k -4 -i -u 'admin:password' https://msgw.docker.local:9443/quickstart/1.0/services

Generate a OAuth access token with the scope (both scopes for **/token** and **/beers**) via curl and the OAuth 2.0 Client Credentials Grant and same as ACCESS_TOKEN environment variable. You can also generate the OAuth access token from the MAS/OTK [OAuth Manager](https://mas.docker.local:8443/oauth/v2/client) using any MAS/OTK supported grant type if you only need *oob* scope:

	CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=no-id-token oob' https://mas.docker.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;

Call the Token Exchange service through the MGW with an OAuth Bearer access token:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://msgw.docker.local:9443/token

The **/validate** endpoint on the MS will require a valid JWT is sent from the MGW. The MS will validate the JWT's signature, TTL, and audience. The JWT's signature is verified from the MGW public JWKs endpoint and the TTL are from the *iat* and *nbf* times.

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://msgw.docker.local:9443/token/validate

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token and the *headers* parameter. Inspect the 'x-ca-jwt' header passed from the MGW.

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://msgw.docker.local:9443/token/validate?headers=true

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token, the *headers* parameter, and the *jwt* parameter. Inspect the JWT decoded response payload:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://msgw.docker.local:9443/token/validate?headers=true&jwt=true'


### <a name="token_exchange"></a>Token Exchange:

The **/exchange** endpoint on the MS simulates a server-to-service call in a heterogenous MS environment. I.E. If ServiceA requires data from ServiceB. The **exchange** resource will require a valid JWT from the MGW and will also validate the JWT (same as above). The **exchange** endpoint will send the JWT to the OAuth Token Exchange endpoint to generate a new impersonation JWT. This new JWT will be used to call a downstream service and aggregate the results in the body. For the example below: MGW -> API -> API2.

Call the Token Exchange service **exchange** resource through the MGW with an OAuth Bearer access token and the *service* parameter to indicate a downstream MS. 

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://msgw.docker.local:9443/token/exchange?service=http://api2:8000/validate'

Call the Token Exchange service **exchange** resource through the MGW with an OAuth Bearer access token and the *service*, the *headers*, and the *jwt* parameter. Inspect the JWT decoded response(s) payload:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://msgw.docker.local:9443/token/exchange?service=http://api2:8000/validate&headers=true&jwt=true'



## <a name="development"></a>Development:

### Custom certificates:

Create custom x509 server certificates and keys for the MAS/OTK and MGW services. This requires **openssl** to be installed on your local system.

Create the self-signed certificate for the MGW using 'msgw.docker.local' as the subject and SAN

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/msgw.key -subj "/CN=msgw.docker.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:msgw.docker.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/msgw.cert.pem

Create the self-signed certificate for the MAS/OTK using 'mas.docker.local' as the subject and SAN

	openssl req -new -x509 -days 730 -nodes -newkey rsa:4096 -keyout config/certs/mas.key -subj "/CN=mas.docker.local" -config <(sed 's/\[ v3_ca \]/\[ v3_ca \]\'$'\nsubjectAltName=DNS:mas.docker.local/' /usr/local/etc/openssl/openssl.cnf) -out config/certs/mas.cert.pem

Convert the PEM certificates to PKCS12:

	openssl pkcs12 -export -clcerts -in config/certs/msgw.cert.pem -inkey config/certs/msgw.key -out config/certs/msgw.cert.p12
	openssl pkcs12 -export -clcerts -in config/certs/mas.cert.pem -inkey config/certs/mas.key -out config/certs/mas.cert.p12


### Import MGW public certificate to MAS/OTK FIP:

Update the FIP on the MAS/OTK instance with the MGW public certificate base64. This is handled currently by the [x-add-otk-user.sh](files/mas/provision/x-add-otk-user.sh) during the container instantiation.

	source .custom.env; ./files/mas/provision/add-otk-user.sh localhost:8443 "admin" 'password' "Gateway as a Client Identity Provider" "msgw.docker.local" `echo $MGW_SSL_PUBLIC_CERT_B64`


### LAC Request logs:

Create a new Request event to view the client traffic

	var message = req.getClientAddress() + ' [' + JSON.parse(JSON.stringify(new Date()))  + '] ' + '\"' + req.verb + ' ' + req.fullBaseURL + '\"';
	out.println(message);


### Export bundles:

Export custom RouteHttp if JWT payload has been modified and update if existing 'NewOrUpdate':

	~/API/packages/gateway_migration/GatewayMigrationUtility.sh migrateOut --defaultAction NewOrUpdate -u admin -h msgw.docker.local -p 9443 --plaintextPassword password --trustCertificate --trustHostname --plaintextEncryptionPassphrase 7layer --policyName RouteHttp -d files/msgw/bundles/RouteHttp.bundle

	~/API/packages/gateway_migration/GatewayMigrationUtility.sh migrateOut -u admin -h mas.docker.local -p 8443 -u admin --plaintextPassword password --trustCertificate --trustHostname --plaintextEncryptionPassphrase 7layer --folderName proxy -d files/mas/bundles/proxy_folder.bundle


### Testing Token Exchange URL:

	curl -i -4 -k -X POST -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:jwt' --data-urlencode 'subject_token=eyJhbGciOiJFUzI1NiIsImtpZCI6IjE2In0.eyJhdWQiOiJodHRwczovL2FzLmV4YW1wbGUuY29tIiwiaXNzIjoiaHR0cHM6Ly9vcmlnaW5hbC1pc3N1ZXIuZXhhbXBsZS5uZXQiLCJleHAiOjE0NDE5MTA2MDAsIm5iZiI6MTQ0MTkwOTAwMCwic3ViIjoiYmNAZXhhbXBsZS5uZXQiLCJzY3AiOlsib3JkZXJzIiwicHJvZmlsZSIsImhpc3RvcnkiXX0.JDe7fZ267iIRXwbFmOugyCt5dmGoy6EeuzNQ3MqDek5cCUlyPhQC6cz9laKjK1bnjMQbLJqWix6ZdBI0isjsTA' https://msgw.docker.local/auth/oauth/v2/token/exchange --data-urlencode 'audience=abc.com333' --data 'debug=true'

