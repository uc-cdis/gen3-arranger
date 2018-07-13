# To run: docker run -d --name=dataportal -p 80:80 quay.io/cdis/data-portal 
# To check running container: docker exec -it dataportal /bin/bash

FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        sudo \
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
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /mnt/ssl/service.key -out /mnt/ssl/service.crt -subj '/countryName=US/stateOrProvinceName=Illinois/localityName=Chicago/organizationName=CDIS/organizationalUnitName=PlanX/commonName=localhost/emailAddress=ops@cdis.org'
COPY . /arranger
RUN useradd -m -s /bin/bash gen3 \
  && chown -R gen3: /arranger \
  && cp /arranger/dockerHelpers/sudoers /etc/sudoers \
  && rm /arranger/dockerHelpers/sudoers 

USER gen3

WORKDIR /arranger
RUN COMMIT=`git rev-parse HEAD` && echo "export const arrangerCommit = \"${COMMIT}\";" > versions.js \
    && VERSION=`git describe --always --tags` && echo "export const arrangerVersion =\"${VERSION}\";" >> versions.js \
    && /bin/rm -rf .git \
    && /bin/rm -rf node_modules \
    && npm ci \
    && npm run compile

# 
# Do some cleanup to trim down the image
#
USER root
RUN bash /arranger/dockerHelpers/dockerCleanup.sh && rm /arranger/dockerHelpers/dockerCleanup.sh

USER gen3

CMD bash dockerHelpers/dockerStart.sh
