# To run: docker run -d --name=dataportal -p 80:80 quay.io/cdis/data-portal 
# To check running container: docker exec -it dataportal /bin/bash

FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        vim \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \ 
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

#
# In standard prod these will be overwritten by volume mounts
# Provided here for ease of use in development and 
# non-standard deployment environments
#
RUN mkdir /mnt/ssl \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /mnt/ssl/nginx.key -out /mnt/ssl/nginx.crt -subj '/countryName=US/stateOrProvinceName=Illinois/localityName=Chicago/organizationName=CDIS/organizationalUnitName=PlanX/commonName=localhost/emailAddress=ops@cdis.org'
COPY . /arranger
RUN useradd -m -s /bin/bash gen3 && chown -R gen3: /arranger
USER gen3

WORKDIR /arranger
RUN COMMIT=`git rev-parse HEAD` && echo "export const arrangerCommit = \"${COMMIT}\";" > versions.js \
    && VERSION=`git describe --always --tags` && echo "export const arrangerVersion =\"${VERSION}\";" >> versions.js \
    && /bin/rm -rf .git \
    && /bin/rm -rf node_modules \
    && npm ci \
    && npm run compile

CMD node bin/server.js
