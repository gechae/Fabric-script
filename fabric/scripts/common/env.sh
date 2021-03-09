#!/bin/bash
set -a
# ====== default ======
DOCKER_NETOWRK_NM=test
CA_TLS_ENABLE=false
CAADMINID=admin
CAADMINPW=adminpw
#array ex) SUBDOMAIN=(google naver)
DOMAIN=com
ENABLE_NODEOU=false

# ------------------- container Setting
# ====== CA Peer ======
CA_PEER_ORG_NAME=ca.peer
#array ex) CA_PEER_PORT=(7060 7061)
CA_PEER_SUBDOMAIN=(google naver)
CA_PEER_PORT=(7060 7061)
PEER_ID=peer
PEER_USER_ID=user

# ====== CA Orderer ======
ORD_ENABLE=true
CA_ORD_ORG_NAME=ca.orderer
#array ex) CA_ORD_PORT=(8060 8061)
CA_ORD_SUBDOMAIN=(google)
CA_ORD_PORT=(8060)
ORD_ID=orderer
ORD_USER_ID=

# -------------------- crypto&container Setting
# ====== Peer ======
PEER_CNT=2
#PEER_ORG_NAME=peer
#PEER_PORT=9090+N
PEER_PORT=(9090 10090)

# ====== Orderer ======
ORD_ENABLE=false
ORD_CNT=3
#ORD_ORG_NAME=orderer
#ORD_PORT=10010 + N
ORD_PORT=10010

