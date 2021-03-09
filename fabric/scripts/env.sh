#!/bin/bash
set -a
# ====== default ======
DOCKER_NETOWRK_NM=test
CA_TLS_ENABLE=true
CAADMINID=admin
CAADMINPW=adminpw
#array ex) SUBDOMAIN=(google naver)
SUBDOMAIN=(google)
DOMAIN=com

# ------------------- container Setting
# ====== CA Peer ======
CA_PEER_ORG_NAME=ca.peer
#array ex) CA_PEER_PORT=(7060 7061)
CA_PEER_PORT=(7060)
CA_PEER_USER_ID=user1
CA_PEER_USER_PW=user1pw
CA_PEER_ID=peer1
CA_PEER_PW=peer1pw

# ====== CA Orderer ======
ORD_ENABLE=true
CA_ORD_ORG_NAME=ca.orderer
#array ex) CA_ORD_PORT=(8060 8061)
CA_ORD_PORT=(8060)
CA_ORD_USER_ID=user1
CA_ORD_USER_PW=user1pw
CA_ORD_ID=orderer1
CA_ORD_PW=orderer1pw

# -------------------- crypto&container Setting
# ====== Peer ======
PEER_CNT=2
#PEER_ORG_NAME=peer
#PEER_PORT=9090+N
PEER_PORT=9090

# ====== Orderer ======
ORD_ENABLE=true
ORD_CNT=2
#ORD_ORG_NAME=orderer
#ORD_PORT=10010 + N
ORD_PORT=10010

