#!/bin/bash

. ./scripts/env.sh

COMPOSE_DIR=${PWD}/compose-files
cd $COMPOSE_DIR
function createComposefile(){
	./compose-ca-generate.sh
}
function startCA() {
	createComposefile
	docker-compose -p $DOCKER_NETOWRK_NM -f docker-compose-ca.yaml up -d setup
}

#function startOrderer {}

#function startPeer{}
if [ "$1" == "init" ]; then
#	docker-compose -f ./compose-files/docker-compose.yaml up -d setup
	startCA
elif [ "$1" == "up" ]; then
	docker-compose up -d 
elif [ "$1" == "down" ]; then
	echo $DOCKER_NETOWRK_NM
	docker-compose -p $DOCKER_NETOWRK_NM down --volumes --remove-orphans
	docker network prune -f
	docker volume prune -f
elif [ "$1" == "ca" ] ; then
	docker-compose -f ./docker-compose-ca.yaml -p test up -d ca.peer.google.com
	docker-compose -f ./docker-compose-ca.yaml -p test up -d ca.orderer.google.com
elif [ "$1" == "setup" ] ; then
	docker-compose -f ./docker-compose-ca.yaml -p test up -d setup 
fi

