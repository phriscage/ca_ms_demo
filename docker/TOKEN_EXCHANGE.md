# Microservices Demo (MSD): Token Exchange Configuration 
In this tutorial we will extend the Microservices Demo (MSD) configuration and setup for Token Exchange examples. The same pre-requisites are required


*	[README](README.md)
*	[Token Bridge](#token_bridge) - How the MGW provides token bridging from OAuth to JWT
*	[Token Exchange](#token_exchange) - How the MAS provides token exchange for service-to-service AuthN/AuthZ

### <a name="token_bridge"></a>Token Bridge:

The Token Exchange Python service returns some basic host information (hostname, ip_address) and the coresponding request headers. The [Quickstart Token Exchange example](files/mgw/quickstart/token_exchange.json) is leveraging the MGW's 'RequireOauth2Token' to validate an OAuth Bearer access token with the OAuth hub of the MAS/OTK instance. CORS and Ratelimiting are also included to proteect the MS. The Quickstart JSON file is below:

Create the Token Exchange demo service:

	curl -k -4 -i -u 'admin:password' https://mgw.docker.local:9443/quickstart/1.0/services --data @files/mgw/quickstart/token_exchange.json

Check the service exists:

	curl -k -4 -i -u 'admin:password' https://mgw.docker.local:9443/quickstart/1.0/services

Generate a OAuth access token with the scope (both scopes for **/token** and **/beers**) via curl and the OAuth 2.0 Client Credentials Grant and same as ACCESS_TOKEN environment variable. You can also generate the OAuth access token from the MAS/OTK [OAuth Manager](https://mas.docker.local:8443/oauth/v2/client) using any MAS/OTK supported grant type if you only need *oob* scope:

	CLIENT_ID=54f0c455-4d80-421f-82ca-9194df24859e; CLIENT_SECRET=a0f2742f-31c7-436f-9802-b7015b8fd8e7; export ACCESS_TOKEN=`curl -s -4 -k -X POST 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "client_secret=$CLIENT_SECRET" --data-urlencode 'grant_type=client_credentials' --data-urlencode 'scope=mas_storage oob' https://mas.docker.local:8443/auth/oauth/v2/token | python  -c "import sys, json; print json.load(sys.stdin)['access_token']"`; echo $ACCESS_TOKEN;

Call the Token Exchange service through the MGW with an OAuth Bearer access token:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.docker.local:9443/token

The **/validate** endpoint on the MS will require a valid JWT is sent from the MGW. The MS will validate the JWT's signature, TTL, and audience. The JWT's signature is verified from the MGW public JWKs endpoint and the TTL are from the *iat* and *nbf* times.

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.docker.local:9443/token/validate

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token and the *headers* parameter. Inspect the 'x-ca-jwt' header passed from the MGW.

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" https://mgw.docker.local:9443/token/validate?headers=true

Call the Token Exchange service **validate** resource through the MGW with an OAuth Bearer access token, the *headers* parameter, and the *jwt* parameter. Inspect the JWT decoded response payload:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mgw.docker.local:9443/token/validate?headers=true&jwt=true'


### <a name="token_exchange"></a>Token Exchange:

The **/exchange** endpoint on the MS simulates a server-to-service call in a heterogenous MS environment. I.E. If ServiceA requires data from ServiceB. The **exchange** resource will require a valid JWT from the MGW and will also validate the JWT (same as above). The **exchange** endpoint will send the JWT to the OAuth Token Exchange endpoint to generate a new impersonation JWT. This new JWT will be used to call a downstream service and aggregate the results in the body. For the example below: MGW -> API -> API2.

Call the Token Exchange service **exchange** resource through the MGW with an OAuth Bearer access token and the *service* parameter to indicate a downstream MS. 

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mgw.docker.local:9443/token/exchange?service=http://api2:8000/validate'

Call the Token Exchange service **exchange** resource through the MGW with an OAuth Bearer access token and the *service*, the *headers*, and the *jwt* parameter. Inspect the JWT decoded response(s) payload:

	curl -k -4 -i -H "Authorization: Bearer $ACCESS_TOKEN" 'https://mgw.docker.local:9443/token/exchange?service=http://api2:8000/validate&headers=true&jwt=true'


### Testing Token Exchange URL:

	curl -i -4 -k -X POST -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:jwt' --data-urlencode 'subject_token=eyJhbGciOiJFUzI1NiIsImtpZCI6IjE2In0.eyJhdWQiOiJodHRwczovL2FzLmV4YW1wbGUuY29tIiwiaXNzIjoiaHR0cHM6Ly9vcmlnaW5hbC1pc3N1ZXIuZXhhbXBsZS5uZXQiLCJleHAiOjE0NDE5MTA2MDAsIm5iZiI6MTQ0MTkwOTAwMCwic3ViIjoiYmNAZXhhbXBsZS5uZXQiLCJzY3AiOlsib3JkZXJzIiwicHJvZmlsZSIsImhpc3RvcnkiXX0.JDe7fZ267iIRXwbFmOugyCt5dmGoy6EeuzNQ3MqDek5cCUlyPhQC6cz9laKjK1bnjMQbLJqWix6ZdBI0isjsTA' https://mgw.docker.local/auth/oauth/v2/token/exchange --data-urlencode 'audience=abc.com333' --data 'debug=true'

