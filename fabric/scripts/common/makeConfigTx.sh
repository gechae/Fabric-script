#!/bin/bash
. ./scripts/env.sh
function createConfigTx() {
{ echo "
Organizations:"
  for SUBDOMAIN in ${CA_ORD_SUBDOMAIN[@]}; do
  echo "  - &orderer
      Name: ordererMSP
      ID: ordererMSP
      MSPDir : ${PWD}/organizations/ordererOrganizations/${SUBDOMAIN}.${DOMAIN}/msp

      Policies:
        Readers:
          Type: ImplicitMeta
          Rule: \"ANY Readers\"
        Writers:
          Type: ImplicitMeta
          Rule: \"ANY Writers\"
        Admins:
          Type: Signature
          Rule: \"OR('${SUBDOMAIN}MSP.admin')\"
       
      OrdererEndPoints: "
    PORTCNT=${ORD_PORT}
    for (( NUM=1; NUM<=${ORD_CNT}; NUM++ )); do
      echo "        - orderer${NUM}.${SUBDOMAIN}.${DOMAIN}:${PORTCNT}"
    PORTCNT=$((PORTCNT + 1))
    done 
  done
  
  idx=0 
  for SUBDOMAIN in ${CA_PEER_SUBDOMAIN[@]}; do
   echo "  - &${SUBDOMAIN}
      Name: ${SUBDOMAIN}MSP
      ID: ${SUBDOMAIN}MSP
      MSPDir: ${PWD}/organizations/peerOrganizations/${SUBDOMAIN}.${DOMAIN}/msp
      
      Policies:
        Readers:
          Type: ImplicitMeta
          Rule: \"ANY Readers\"
        Writers:
          Type: ImplicitMeta
          Rule: \"ANY Writers\"
        Admins:
          Type: Signature
          Rule: \"OR('${SUBDOMAIN}MSP.admin')\"
        Endorsement:
          Type: ImplicitMeta
          Rule: \"ANY Writers\"
      AnchorPeers:
        - Host: peer1.${SUBDOMAIN}.${DOMAIN}
          Port: ${PEER_PORT[$idx]} "
   idx=$((idx + 1))
   done

echo "
Capabilities:
  Channel: &ChannelCapabilities
    V2_0: true
  Orderer: &OrdererCapabilities
    V2_0: true
  Application: &ApplicationCapabilities
    V2_0: true
 
Application: &ApplicationDefaults
  Organizations:

  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    LifecycleEndorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"
    Endorsement:
      Type: ImplicitMeta
      Rule: \"MAJORITY Endorsement\"
  Capabilities:
    <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
  OrdererType: etcdraft

  #Addresses:
    #- orderer.example.com:7050   
  EtcdRaft: 
    Consenters:"
  PORTCNT=${ORD_PORT}
  for SUBDOMAIN in ${CA_ORD_SUBDOMAIN[@]}; do
    for ((NUM=1; NUM<=${ORD_CNT}; NUM++)) do
    echo "    - Host: orderer${NUM}.${SUBDOMAIN}.${DOMAIN}
      Port: ${PORTCNT}
      ClientTLSCert: ${PWD}/crypto-config/organizations/ordererOrganizations/${SUBDOMAIN}.${DOMAIN}/orderers/orderer${NUM}.${SUBDOMAIN}.${DOMAIN}/tls/server.crt
      ServerTLSCert: ${PWD}/crypto-config/organizations/ordererOrganizations/${SUBDOMAIN}.${DOMAIN}/orderers/orderer${NUM}.${SUBDOMAIN}.${DOMAIN}/tls/server.crt"
  PORTCNT=$((PORTCNT + 1))
    done
  done

  echo "  BatchTimeout: 2s
  BatchSize:
    MaxMessageCount: 10
    AbsoluteMaxBytes: 99 MB
    PreferredMaxBytes: 512 KB

  Organizations:

  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
    BlockValidation:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"

Channel: &ChannelDefaults
  Policies:
    Readers:
      Type: ImplicitMeta
      Rule: \"ANY Readers\"
    Writers:
      Type: ImplicitMeta
      Rule: \"ANY Writers\"
    Admins:
      Type: ImplicitMeta
      Rule: \"MAJORITY Admins\"
  Capabilities:
    <<: *ChannelCapabilities

Profiles:
  TwoOrgsOrdererGenesis:
    <<: *ChannelDefaults
    Orderer:
       <<: *OrdererDefaults
       Organizations:
         - *orderer
       Capabilities:
         <<: *OrdererCapabilities
    Consortiums:
        SampleConsortium:
            Organizations:"
  for SUBDOMAIN in ${CA_PEER_SUBDOMAIN[@]}; do
              echo "              - *${SUBDOMAIN}"
  done


echo "  TwoOrgsChannel:
      Consortium: SampleConsortium
      <<: *ChannelDefaults
      Application:
        <<: *ApplicationDefaults
        Organizations:"
  for SUBDOMAIN in ${CA_PEER_SUBDOMAIN[@]}; do
              echo "              - *${SUBDOMAIN}"
  done
echo "        Capabilities:
                <<: *ApplicationCapabilities"
} > /root/data/configtx.yaml

}
