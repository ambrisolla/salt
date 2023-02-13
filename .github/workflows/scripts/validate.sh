#!/bin/bash


TEST_STATES_DIR=$1
TEST_PILLAR_DIR=$2
TEST_SALT_ENV=$3


LOG_FILE="/tmp/$(echo $0 | awk -F'/' '{print $NF}')-error.log"

# States
STATES=$( 
  find ${TEST_STATES_DIR} -name "*.sls" | \
  egrep -v "top.sls$|\/reactor\/|\/win/\repo-ng\/" | \
  sed "s/\/init.sls//g;s/.sls//g" | \
  sed "s@${TEST_STATES_DIR}\/@@g" | \
  sed "s/\//./g" )
for state in ${STATES[@]}
do
  test=$( salt-call state.sls_exists ${state} saltenv=${TEST_SALT_ENV} --out=json 2>> ${LOG_FILE} | jq -r '.local' )
  case "${test}" in
    true)  message="PASSED" ;;
    false) message="FAILED" ;;
  esac
  echo -ne " - checking state ${state}... ${message}\n\n"
  status_list+=(${test})
done

# Pillars
PILLARS=$( find ${TEST_PILLAR_DIR} -name "*.sls" )
for pillar in ${PILLARS[@]}
do
test=$( salt-call pillar.file_exists ${pillar} saltenv=${TEST_SALT_ENV} --out=json 2>> ${LOG_FILE} | jq -r '.local' )
  case "${test}" in
    true)  message="PASSED" ;;
    false) message="FAILED" ;;
  esac
  echo -ne " - checking pillar file ${pillar}... ${message}\n"
  status_list+=(${test})
done

if [[ "${status_list[*]}"  =~ "false" ]]
then
  echo -ne "\n - Error: Failed to check states!"
  exit 1
else
  echo -ne "\n - Success: States check completed!"
fi