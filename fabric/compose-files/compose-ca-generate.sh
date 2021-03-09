#!/bin/bash
. ../scripts/common/env.sh

{ echo "
version: \"3.3\"

networks:
  network:
    ipam:
      driver: default
      config:
        - subnet: "220.100.30.0/24"

services:
  setup:
    container_name: setup
    #extends:
    #  file: peer-base.yaml
    #  service: ca-env
    image: hyperledger/fabric-ca:1.4.9
    environment:
      - ORDERER_HOME=/etc/hyperledger/orderer
      - PEER_HOME=/opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash -c '/scripts/mkMsp.sh; sleep 99999'
    volumes:
      - ../scripts/common:/scripts
      - ../crypto-config:/crypto-config
      - ../channel-artifacts:/root/data
      - ../organizations:/organizations
      - ../bin:/extra_bin
    networks:
      - network
    depends_on: "
    for SD in ${CA_PEER_SUBDOMAIN[@]}; do
	echo "      - $CA_PEER_ORG_NAME.$SD.$DOMAIN"
    done
    for SD in ${CA_ORD_SUBDOMAIN[@]}; do
	echo "      - $CA_ORD_ORG_NAME.$SD.$DOMAIN"
    done

  idx=0
  for SD in ${CA_PEER_SUBDOMAIN[@]}; do
  echo "
  $CA_PEER_ORG_NAME.$SD.$DOMAIN:
    container_name : $CA_PEER_ORG_NAME.$SD.$DOMAIN
    image: hyperledger/fabric-ca:1.4.9
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=$CA_PEER_ORG_NAME.$SD.$DOMAIN
      #- FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=${CA_PEER_PORT[$idx]}
      - FABRIC_CA_SERVER_CSR_CN=finger
    ports:
      - ${CA_PEER_PORT[$idx]}:${CA_PEER_PORT[$idx]}
    command: sh -c 'fabric-ca-server start -b $CAADMINID:$CAADMINPW -d'
    volumes:
      - ../data/ca/fabric-ca/$CA_PEER_ORG_NAME.$SD.$DOMAIN:/etc/hyperledger/fabric-ca-server
    networks:
      - network
  "
  idx=$((idx + 1))
  done

  idx=0
  for SD in ${CA_ORD_SUBDOMAIN[@]}; do
  echo "
  $CA_ORD_ORG_NAME.$SD.$DOMAIN:
    container_name: $CA_ORD_ORG_NAME.$SD.$DOMAIN
    image: hyperledger/fabric-ca:1.4.9
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=$CA_ORD_ORG_NAME.$SD.$DOMAIN
      #- FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=${CA_ORD_PORT[$idx]}
    ports:
      - ${CA_ORD_PORT[$idx]}:${CA_ORD_PORT[$idx]}
    command: sh -c 'fabric-ca-server start -b $CAADMINID:$CAADMINPW -d'
    volumes:
      - ../data/ca/fabric-ca/$CA_ORD_ORG_NAME.$SD.$DOMAIN:/etc/hyperledger/fabric-ca-server
    networks:
      - network 
  "
  idx=$((idx + 1))
  done
} > ./docker-compose-ca.yaml
