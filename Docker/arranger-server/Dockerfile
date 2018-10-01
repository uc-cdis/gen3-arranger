FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get upgrade -y\
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        sudo \
        vim \
    && curl -sL https://deb.nodesource.com/setup_10.x | bash - \ 
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/overture-stack/arranger.git \
    && cd arranger \
    && npm i \
    && npm run bootstrap 

EXPOSE 5050

WORKDIR /arranger/modules/server
CMD npm run run-prod
