#!/bin/bash

# BIG-IP ONBOARD SCRIPT

LOG_FILE=${onboard_log}

if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi

exec 1>$LOG_FILE 2>&1

# CHECK TO SEE NETWORK IS READY
CNT=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 6 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

mkdir -p ${libs_dir}
# Could be pre-packaged or hosted internally
curl -o /config/cloud/f5-cloud-libs.tar.gz --silent --fail --retry 60 -L https://github.com/F5Networks/f5-cloud-libs/archive/v4.13.5.tar.gz
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C ${libs_dir}/
mv ${libs_dir}/f5-cloud-libs-* ${libs_dir}/f5-cloud-libs
mkdir ${libs_dir}/f5-cloud-libs/node_modules
tar xvfz /config/cloud/f5-cloud-libs.tar.gz -C ${libs_dir}/f5-cloud-libs/node_modules

### BEGIN BASIC ONBOARDING 
# WAIT FOR MCPD (DATABASE) TO BE UP TO BEGIN F5 CONFIG
. ${libs_dir}/f5-cloud-libs/scripts/util.sh
wait_for_bigip

# CHECK TO SEE NETWORK IS READY AGAIN - github.com was not resolvable sometimes at this stage
CNT=0
while true
do
  STATUS=$(curl -s -k -I example.com | grep HTTP)
  if [[ $STATUS == *"200"* ]]; then
    echo "Got 200! VE is Ready!"
    break
  elif [ $CNT -le 10 ]; then
    echo "Status code: $STATUS  Not done yet..."
    CNT=$[$CNT+1]
  else
    echo "GIVE UP..."
    break
  fi
  sleep 10
done

### DOWNLOAD ONBOARDING PKGS
# Could be pre-packaged or hosted internally

DO_URL='${DO_URL}'
DO_FN=$(basename "$DO_URL")
AS3_URL='${AS3_URL}'
AS3_FN=$(basename "$AS3_URL")
TS_URL='${TS_URL}'
TS_FN=$(basename "$TS_URL")

echo -e "\n"$(date) "Download Declarative Onboarding Pkg"
curl -L -o ${libs_dir}/$DO_FN $DO_URL

echo -e "\n"$(date) "Download AS3 Pkg"
curl -L -o ${libs_dir}/$AS3_FN $AS3_URL

echo -e "\n"$(date) "Download TS Pkg"
curl -L -o ${libs_dir}/$TS_FN $TS_URL
sleep 20

# Copy the RPM Pkg to the file location
cp ${libs_dir}/*.rpm /var/config/rest/downloads/

# Install Declarative Onboarding Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$DO_FN\"}"
echo -e "\n"$(date) "Install DO Pkg"
restcurl -X POST "shared/iapp/package-management-tasks" -d $DATA

# Install AS3 Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$AS3_FN\"}"
echo -e "\n"$(date) "Install AS3 Pkg"
restcurl -X POST "shared/iapp/package-management-tasks" -d $DATA

# Install TS Pkg
DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/$TS_FN\"}"
echo -e "\n"$(date) "Install TS Pkg"
restcurl -X POST "shared/iapp/package-management-tasks" -d $DATA

# SET BIG-IP PASSWORD
echo "SET THE BIG-IP PASSWORD"
pwd='${BIGIP_PASS}'
if [ -z "$pwd" ]
then
  echo "ERROR: UNABLE TO OBTAIN PASSWORD"
else
  tmsh modify auth user admin password $pwd

  tmsh save sys config
fi

sleep 20

# Enable iApps LX Package management in UI
echo  "ENABLE IAPPS LX PACKAGE MANAGEMENT IN UI"
touch /var/config/rest/iapps/enable

# Restart restnoded to work around https://github.com/F5Networks/f5-appsvcs-extension/issues/108
echo  "RESTARTING RESTNODED"
bigstart restart restnoded

sleep 10