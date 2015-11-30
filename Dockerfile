FROM debian:jessie

RUN apt-get update && \
    apt-get install -y wget curl vim nano less openssh-client 
