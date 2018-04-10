FROM ubuntu:rolling

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install \
        devscripts debhelper build-essential \
        python3-launchpadlib python3-debian python3-pip && \
    rm -r /var/cache/apt/archives /var/lib/apt/lists && \
    pip3 install whelk

ADD bin /usr/bin
ADD resource /opt/resource
