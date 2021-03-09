#!/bin/bash
. ./env.sh
{ echo "
Organizations:"
  for SUBDOMAIN in ${CA_ORD_SUBDOMAIN[@]}; do
  echo " - &${SUBDOMAIN}orderer
      Name: ${SUBDOMAIN}OrdererMSP
      ID: ${SUBDOMAIN}OrdererMSP
      MSPDir : ${PWD}/crypto-config/ordererOrganizations/$HOSTNAME/msp

      Policies:
          Readers:
              Type: ImplicitMeta
              Rule: \"ANY Readers\"
          Writers:
              Type: ImpliciMeta
              Rule: \"ANY Writers\"
          Admins:
              Type: Signature
              Rule: \"OR('${SUBDOMAIN}MSP.admin')\"

      OrdererEndPoints: "
      for (( NUM=1; NUM<=${ORD_CNT}; NUM++ ));
      do
        echo " - orderer${NUM}.${SUBDMAIN}.${DOMAIN}:${CA_ORD_PORT[$NUM]}"
      done
  done
} > ./test.txt
