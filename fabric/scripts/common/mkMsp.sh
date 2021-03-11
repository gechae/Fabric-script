#!/bin/bash
. ./scripts/env.sh

function enrollAdmin() {

  set -x

  CA_HOSTNAME=$1
  CA_PORT=$2
  HOSTNAME=$3
  NODEPATH=$4

  { set +x; } 2>/dev/null

  echo "Enroll the CA Admin"
  mkdir -p organizations/$NODEPATH/$HOSTNAME/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/$NODEPATH/$HOSTNAME
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
  #ORG_ADMIN=$6

  { set +x; } 2>/dev/null

  # create peer
  echo "Register ${PEER_USER_ID}${CNT}"
  set -x
  fabric-ca-client register -u $SCHEME://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT} --id.name ${PEER_USER_ID}${CNT} --id.secret ${PEER_USER_ID}${CNT}pw --id.type peer $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers
  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME

  echo "Generate the ${PEER_USER_ID}${CNT}"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/msp --csr.hosts $PEER_HOSTNAME $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  echo "Generate the ${PEER_USER_ID}${CNT}-tls certificates"
  set -x
  fabric-ca-client enroll -u $SCHEME://${PEER_USER_ID}${CNT}:${PEER_USER_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls --enrollment.profile tls --csr.hosts $PEER_HOSTNAME --csr.hosts ${CA_HOSTNAME} $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  
  # TLS 인증서 복사
  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls
  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/ca.crt

  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/server.crt

  cp ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/keystore/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/tls/server.key

 # admincerts 인증서 작업 
  set -x
  
  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/peers/${PEER_HOSTNAME}/msp/{admincerts,cacerts,keystore,signcerts,tlscacerts}
  cp -rf ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/${PEER_HOSTNAME}/msp/cacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/peers/${PEER_HOSTNAME}/msp/cacerts/
  cp -rf ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/${PEER_HOSTNAME}/msp/keystore/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/peers/${PEER_HOSTNAME}/msp/keystore/server.key
  cp -rf ${PWD}/organizations/peerOrganizations/$HOSTNAME/peers/${PEER_HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/peers/${PEER_HOSTNAME}/msp/signcerts/${PEER_HOSTNAME}-cert.pem
  cp -rf ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/$PEER_HOSTNAME/msp/cacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/peers/${PEER_HOSTNAME}/msp/tlscacerts/tlsca.${PEER_HOSTNAME}-cert.pem

  cp -rf ${PWD}/organizations/peerOrganizations/$HOSTNAME/users/Admin@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/$HOSTNAME/peers/${PEER_HOSTNAME}/msp/admincerts/Admin@$HOSTNAME-cert.pem
  { set +x; } 2> /dev/null

}

function enrollOrderer() {

  set -x 

  CA_HOSTNAME=$1
  CA_PORT=$2
  PEER_HOSTNAME=$3
  HOSTNAME=$4
  CNT=$5
  #ORG_ADMIN=$6

  { set +x; } 2>/dev/null

  echo "Enroll the CA Admin"
  mkdir -p organizations/ordererOrganizations/$HOSTNAME

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/$HOSTNAME
  #  rm -rf $FABRIC_CA_CLIENT_HOME/fabric-ca-client-config.yaml
  #  rm -rf $FABRIC_CA_CLIENT_HOME/msp

  set -x
  fabric-ca-client enroll -u $SCHEME://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT} $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  echo "Register orderer"
  set -x
  fabric-ca-client register -u $SCHEME://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT} --id.name ${ORD_ID}${CNT} --id.secret ${ORD_ID}${CNT}pw --id.type orderer $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  #mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers
  #mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers/example.com

  mkdir -p organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME



  echo "Generate the orderer msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${ORD_ID}${CNT}:${ORD_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/msp --csr.hosts $PEER_HOSTNAME --csr.hosts ${CA_HOSTNAME}  $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  echo "Generate the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u $SCHEME://${ORD_ID}${CNT}:${ORD_ID}${CNT}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls --enrollment.profile tls --csr.hosts ${PEER_HOSTNAME} --csr.hosts ${CA_HOSTNAME}  $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  # TLS 인증서 복사
  mkdir -p ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls
  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/tlscacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/ca.crt

  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/signcerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/server.crt

  cp ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/keystore/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/tls/server.key

 # admincerts 인증서 작업
  set -x

  mkdir -p ${PWD}/crypto-config/organizations/ordererOrganizations/${HOSTNAME}/orderers/${PEER_HOSTNAME}/msp/{admincerts,cacerts,keystore,signcerts,tlscacerts}
  cp -rf ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/${PEER_HOSTNAME}/msp/cacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/${HOSTNAME}/orderers/${PEER_HOSTNAME}/msp/cacerts/
  cp -rf ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/${PEER_HOSTNAME}/msp/keystore/* ${PWD}/crypto-config/organizations/ordererOrganizations/${HOSTNAME}/orderers/${PEER_HOSTNAME}/msp/keystore/server.key
  cp -rf ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/${PEER_HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/${HOSTNAME}/orderers/${PEER_HOSTNAME}/msp/signcerts/${PEER_HOSTNAME}-cert.pem
  cp -rf ${PWD}/organizations/ordererOrganizations/$HOSTNAME/orderers/$PEER_HOSTNAME/msp/cacerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/${HOSTNAME}/orderers/${PEER_HOSTNAME}/msp/tlscacerts/tlsca.${PEER_HOSTNAME}-cert.pem

  cp -rf ${PWD}/organizations/ordererOrganizations/$HOSTNAME/users/Admin@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/ordererOrganizations/$HOSTNAME/orderers/${PEER_HOSTNAME}/msp/admincerts/Admin@$HOSTNAME-cert.pem

}

function enrollUser() {

  # 1개 만
  # create user
  USER_ID=$1

  echo "Register user"
  set -x
  fabric-ca-client register -u $SCHEME://${CAAMDINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT}  --id.name ${USER_ID}  --id.secret ${USER_ID}pw --id.type client $TLS_CERT_PATH
  { set +x; } 2>/dev/null


  #mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users
  mkdir -p ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/{admincerts,cacerts,keystore,signcerts}

  echo "Generate the user msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${USER_ID}:${USER_ID}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  cp -rf ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/admincerts/User@${HOSTNAME}-cert.pem
  cp -rf ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/signcerts/Admin@${HOSTNAME}-cert.pem
  cp -rf ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/keystore/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/keystore/server.key
  cp -rf ${PWD}/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/cacerts/* ${PWD}/crypto-config/organizations/peerOrganizations/${HOSTNAME}/users/User@${HOSTNAME}/msp/cacerts/

}

function enrollAdminUser() {

  # 1개 만
  # create admin
  ORG_ADMIN=$1
  NODE_PATH=$2



  echo "Register the org admin"
  set -x
  fabric-ca-client register -u $SCHEME://${CAADMINID}:${CAADMINPW}@${CA_HOSTNAME}:${CA_PORT}  --id.name ${ORG_ADMIN} --id.secret ${ORG_ADMIN}pw --id.type $CAADMINID $TLS_CERT_PATH
  { set +x; } 2>/dev/null


  mkdir -p ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}

  echo "Generate the org admin msp"
  set -x
  fabric-ca-client enroll -u $SCHEME://${ORG_ADMIN}:${ORG_ADMIN}pw@${CA_HOSTNAME}:${CA_PORT} -M ${PWD}/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp $TLS_CERT_PATH
  { set +x; } 2>/dev/null

  
  mkdir -p ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/{signcerts,cacerts,keystore,admincerts}
  cp -rf ${PWD}/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/admincerts/Admin@${HOSTNAME}-cert.pem
  cp -rf ${PWD}/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/signcerts/* ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/signcerts/User@${HOSTNAME}-cert.pem
  cp -rf ${PWD}/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/keystore/* ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/keystore/server.key
  cp -rf ${PWD}/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/cacerts/* ${PWD}/crypto-config/organizations/${NODE_PATH}/${HOSTNAME}/users/Admin@${HOSTNAME}/msp/cacerts/
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
    for SD in ${CA_PEER_SUBDOMAIN[@]}; do
	CA_HOSTNAME=$CA_PEER_ORG_NAME.$SD.$DOMAIN
	CA_PORT=${CA_PEER_PORT[$idx]}
	HOSTNAME=$SD.$DOMAIN
    	enrollAdmin $CA_HOSTNAME $CA_PORT $HOSTNAME peerOrganizations
    	enrollUser ${PEER_USER_ID} 
    	enrollAdminUser admin_${SD} peerOrganizations
	for ((NUM=1; NUM<=$PEER_CNT; NUM++))
	do 
		PEER_HOSTNAME=peer$NUM.$HOSTNAME
		enrollPeer $CA_HOSTNAME $CA_PORT $PEER_HOSTNAME $HOSTNAME $NUM $SD 
	done
    	idx=$((idx + 1))
    done

}

function createOrderer() {

    init 
    idx=0
    for SD in ${CA_ORD_SUBDOMAIN[@]}; do
        CA_HOSTNAME=$CA_ORD_ORG_NAME.$SD.$DOMAIN
        CA_PORT=${CA_ORD_PORT[$idx]}
        HOSTNAME=$SD.$DOMAIN
        enrollAdmin $CA_HOSTNAME $CA_PORT $HOSTNAME ordererOrganizations
        enrollAdminUser ordadmin_${SD} ordererOrganizations
        for ((NUM=1; NUM<=$ORD_CNT; NUM++))
        do
                PEER_HOSTNAME=orderer$NUM.$HOSTNAME
                enrollOrderer $CA_HOSTNAME $CA_PORT $PEER_HOSTNAME $HOSTNAME $NUM $SD
        done
    	idx=$((idx + 1))
    done
}

function createConsortium() {

export FABRIC_CFG_PATH=/root/data/
. ./scripts/makeConfigTx.sh
coreateConfigTx

/root/data/bin/configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock /root/data/genesis.block


}
set -a 
createPeer
createOrderer
createConsortium
