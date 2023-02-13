#!/bin/bash
#set -e

STATES_DIR="/srv/salt"
PILLAR_DIR="/srv/pillar"
LOG_FILE="teste-states.log"

STATES=$( 
  find ${STATES_DIR} -name "*.sls" | \
  egrep -v "top.sls$|\/reactor\/|\/win/\repo-ng\/" | \
  sed "s/\/init.sls//g;s/.sls//g" | \
  sed "s@$STATES_DIR\/@@g" | \
  sed "s/\//./g" )


for state in ${STATES[@]}
do
  echo -ne " - checking state ${state}... \r"
  test=$( salt-call state.sls_exists ${state} --out=json 2> ${LOG_FILE} | jq -r '.local' )
  case "${test}" in
    true)  message="PASSED" ;;
    false) message="FAILED" ;;
  esac
  echo -ne " - checking state ${state}... ${message}\n"
  status_list+=(${test})
done

if [[ "${status_list[*]}"  =~ "false" ]]
then
  echo -ne "\n - Error: Failed to check states!"
  exit 1
else
  echo -ne "\n - Success: States check completed!"
fi
