#!/bin/bash

STATES_DIR=$1
PILLAR_DIR=$2
SALT_ENV=$3
LOG_FILE="/tmp/$(echo $0 | awk -F'/' '{print $NF}')-error.log"

# States
STATES=$( \
  find ${STATES_DIR} -name "*.sls" | \
  egrep -v "top.sls$|\/reactor\/|\/win/\repo-ng\/" | \
  sed "s/\/init.sls//g;s/.sls//g" | \
  sed "s@${STATES_DIR}\/@@g" | \
  sed "s/\//./g" )
for state in ${STATES[@]}
do
  check=$( salt-call state.sls_exists ${state} saltenv=${SALT_ENV} --out=json 2>> ${LOG_FILE} | jq -r '.local' )
  case "${check}" in
    true)  message="PASSED" ;;
    false) message="FAILED" ;;
  esac
  echo -ne " - checking state: ${state}... ${message}\n"
  status_list+=(${check})
done

## Pillars
PILLARS=$( find ${PILLAR_DIR} -name "*.sls" )
for pillar in ${PILLARS[@]}
do
yaml=$( cat $pillar )
check=$( echo $yaml | yq > /dev/null 2> /dev/null ; echo $? )
  case "${check}" in
    0) message="PASSED"; success=true  ;;
    1) message="FAILED"; success=false ;;
  esac
  echo -ne " - checking pillar file: ${pillar}... ${message}\n"
  status_list+=(${success})
done

if [[ "${status_list[*]}"  =~ "false" ]]
then
  echo -ne "\n - Error: Failed to check Salt Pillars and Salt States !"
  rm -rf ${PILLAR_DIR} ${STATES_DIR}
  exit 1
else
  echo -ne "\n - Success: Salt Pillar and Salt States check completed!"
fi