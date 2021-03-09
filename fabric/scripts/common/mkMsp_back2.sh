#!/bin/bash
. ./scripts/env.sh

function enrollAdmin() {

  set -x

  CA_HOSTNAME=$1
  CA_PORT=$2
  HOSTNAME=$3
  PATH=$4

  { set +x; } 2>/dev/null

  echo "Enroll the CA Admin"
  mkdir -p organizations/$PATH/$HOSTNAME/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/$PATH/$HOSTNAME
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u ${SCHEME}://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT} $TLS_CERT_PATH
  { set +x; } 2>/dev/null


}

function enrollPeer() {
  set -x 

  CA_HOSTNAME=$1
  CA_PORT=$2
  PEER_HOSTNAME=$3
  HOSTNAME=$4
  CNT=$5
  ORG_ADMIN=$6

  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/PATH/$HOSTNAME/msp/config.yaml
fi

  // create peer
  echo "Register peer0"
  set -x
  fabric-ca-client register -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} --id.name ${PEER_USER_ID}${CNT} --id.secret ${PEER_USER_ID}${CNT}pw --id.type peer $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers
  mkdir -p ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME

  echo "Generate the peer0 msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/msp --csr.hosts $PEER_HOSTNAME $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  echo "Generate the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls --enrollment.profile tls --csr.hosts $PEER_HOSTNAME --csr.hosts ${CA_HOSTNAME} $TLS_CERT_PATH
  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/msp/config.yaml ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/msp/config.yaml
fi

  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/ca.crt
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/server.crt
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/keystore/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/server.key

  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/msp/tlscacerts
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/msp/tlscacerts/ca.crt

  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/tlsca
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNMAE/tls/tlscacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/tlsca/tlsca.$HOSTNAME-cert.pem

  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/ca
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/msp/cacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/ca/ca.$HOSTNAME-cert.pem

}

function createOrderer() {

  set -x 

  CA_HOSTNAME=$1
  CA_PORT=$2
  PEER_HOSTNAME=$3
  HOSTNAME=$4
  CNT=$5
  ORG_ADMIN=$6

  { set +x; } 2>/dev/null

  echo "Enroll the CA Admin"
  mkdir -p organizations/ordererOrganizations/$HOSTNAME

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/$HOSTNAME
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u $SCHEME://$CAADMINID:$CAADMINPW@${CA_HOSTNAME}:${CA_PORT} $TLS_CERT_PATH
  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-9054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' >${PWD}/organizations/ordererOrganizations/$HOSTNAME/msp/config.yaml
fi

  echo "Register orderer"
  set -x
  fabric-ca-client register -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}@${CA_HOSTNAME}:${CA_PORT} --id.name orderer --id.secret ordererpw --id.type orderer $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers
  #mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers/example.com

  mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME



  echo "Generate the orderer msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/msp --csr.hosts $PEER_HOSTNAME --csr.hosts localhost  $TLS_CERT_PATH
  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  cp ${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml ${PWD}/crypto-config/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/config.yaml
fi

  echo "Generate the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls --enrollment.profile tls --csr.hosts $PEER_HOSTNAME --csr.hosts localhost  $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/ca.crt
  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/signcerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/server.crt
  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/keystore/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/server.key

  mkdir -p ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/msp/tlscacerts/tlsca.$PEER_HOSTNAME-cert.pem

  mkdir -p ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/msp/tlscacerts
  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HoSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNMAE/msp/tlscacerts/tlsca.$PEER_HOSTNAME-cert.pem

  echo "Register the orderer Admin"
  set -x
  fabric-ca-client register -u ${SCHEME}://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT} --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p /crypto-config/organizations/ordererOrganizations/example.com/users
  mkdir -p /crypto-config/organizations/ordererOrganizations/example.com/users/Admin@example.com

  echo "Generate the $CAADMINID msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://ordererAdmin:ordererAdminpw@localhost:9054 -M ${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  cp ${PWD}/organizations/ordererOrganizations/example.com/msp/config.yaml ${PWD}/crypto-config/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp/config.yaml

}

function enrollUser() {

  // 1개 만
  // create user
  echo "Register user"
  set -x
  fabric-ca-client register -u $SCHEME://${PEER_USER_ID}:${PEER_USER_ID}pw@${CA_HOSTNAME}:${CA_PORT}  --id.name ${USER_ID} --id.secret ${USER_ID}pw --id.type client $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users
  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}

  echo "Generate the user msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${USER_ID}:${USER_ID}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp $TLS_CERT_PATH
  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/msp/config.yaml ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/config.yaml
fi

}

function enrollAdminUser() {

  // 1개 만
  // create admin
  echo "Register the org admin"
  set -x
  fabric-ca-client register -u $SCHEME://${PEER_USER_ID}:${PEER_USER_ID}pw@${CA_HOSTNAME}:${CA_PORT}  --id.name ${ORG_ADMIN} --id.secret ${ORG_ADMIN}pw --id.type $CAADMINID $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/Admin@${HOSTNAME}

  echo "Generate the org admin msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${ORG_ADMIN}:${ORG_ADMIN}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/Admin@${HOSTNAME}/msp $TLS_CERT_PATH
  { set +x; } 2>/dev/null

if [ $ENABLE_NODEOU == true ]; then
  cp ${PWD}/organizations/peerOrganizations/${HOSTNAME}/msp/config.yaml ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/config.yaml
fi

}

function init() {

	if [ ${CA_TLS_ENABLE} == true ]; then
		SCHEME=https
		TLS_CERT_PATH="-tls.certfiles ${PWD}/organizations/fabric-ca/org1/tls-cert.pem"
	elif [ ${CA_TLS_ENABLE} == false ]; then
		SCHEME=http
		TLS_CERT_PATH=
	fi
}

function createPeer() {

    init
    idx=0
    for SD in ${SUBDOMAIN[@]}; do
	CA_HOSTNAME=$CA_PEER_ORG_NAME.$SD.$DOMAIN
	CA_PORT=${CA_PEER_PORT[$idx]}
	HOSTNAME=$SD.$DOMAIN
    	enrollAdmin $CA_HOSTNAME $CA_PORT $HOSTNAME peerOrganizations
	for ((NUM=1; NUM<=$PEER_CNT; NUM++))
	do 
		PEER_HOSTNAME=peer$PNUM.$HOSTNAME
		enrollPeer $CA_HOSTNAME $CA_PORT $PEER_HOSTNAME $HOSTNAME $PNUM $SD
	done
	enrollUser
	enrollAdminUser
    idx=$((idx + 1))
    done

}

function createOrderer() {

    init 
    idx=0
    for SD in ${SUBDOMAIN[@]}; do
        CA_HOSTNAME=$CA_ORD_ORG_NAME.$SD.$DOMAIN
        CA_PORT=${CA_ORD_PORT[$idx]}
        HOSTNAME=$SD.$DOMAIN
        enrollAdmin $CA_HOSTNAME $CA_PORT $HOSTNAME ordererOrganizations
        for ((NUM=1; NUM<=$ORD_CNT; NUM++))
        do
                PEER_HOSTNAME=orderer$PNUM.$HOSTNAME
                enrollOrderer $CA_HOSTNAME $CA_PORT $PEER_HOSTNAME $HOSTNAME $NUM $SD
        done
        enrollUser
        enrollAdminUser
    idx=$((idx + 1))
    done

}

set -a 
createPeer
#createOrderer
