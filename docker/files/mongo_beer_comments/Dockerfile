################################################################################
##  Name:   Dockerfile
##  Date:   2016-10-04
##  Developer:  Chris Page
##  Email:  christopher.page@ca.com
##  Purpose:   This Dockerfile contains the Docker build commands to seed Mongo
###############################################################################
FROM mongo:3.3.15

MAINTAINER Chris Page

COPY beer_comments.json /beer_comments.json
CMD mongoimport --host mongo_beer_comments --db beer_comments --collection beer_comments --type json --file /beer_comments.json --jsonArray
