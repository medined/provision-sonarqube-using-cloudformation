#!/bin/bash

if [ -z $REGION_NAME ]; then
  echo "Set REGION_NAME"
  exit 1
fi

#############################
echo "Saving random password to Parameter Store"
#############################
echo "$(date)" > floop.tmp
RPASSWORD=\$(sha256sum floop.tmp)
rm floop.tmp

aws ssm put-parameter \
  --name sonar-password \
  --value ${RPASSWORD} \
  --type String \
  --overwrite
#
#############################

echo "Sonar started."
aws cloudformation deploy \
  --stack-name "sonar" \
  --region $REGION_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --template-file sonar.yaml

#############################
echo "Getting IP address of SonarQube server."
#############################

HOST_SONAR=$(aws cloudformation list-exports \
  --query "Exports[?Name==\`sonar:PublicIp\`].Value" \
  --output text)

if [ -z ${HOST_SONAR} ]; then
  echo "ERROR: Missing CloudFormat export: sonar:PublicIp";
  exit
fi

#############################
echo "Waiting for SonarQube to start."
#############################

# I tried using the healthcheck url but it started to return the
# empty string even when I knew the server was running. I switched
# to the system status.

STATUS=$(curl --silent -u admin:admin --connect-timeout 2 --max-time 2 http://${HOST_SONAR}:9000/api/system/status | jq -r '.status')
while [ "${STATUS}x" == "x" ]; do
  echo -n "."
  sleep 10
  STATUS=$(curl --silent -u admin:admin --connect-timeout 2 --max-time 2 http://${HOST_SONAR}:9000/api/system/status | jq -r '.status')
done
echo ""

#############################
echo "Waiting for SonarQube to finish starting, after 10 second delay."
#############################

STATUS=$(curl --silent -u admin:admin --connect-timeout 2 --max-time 2 http://${HOST_SONAR}:9000/api/system/status | jq -r '.status')
while [ "${STATUS}x" == "STARTINGx" ]; do
  echo -n "."
  sleep 10
  STATUS=$(curl --silent -u admin:admin --connect-timeout 2 --max-time 2 http://${HOST_SONAR}:9000/api/system/status | jq -r '.status')
done
echo ""

#############################
echo "Verifying that SonarQube is UP, after 2 second delay."
#############################

sleep 2
STATUS=$(curl --silent -u admin:admin --connect-timeout 2 --max-time 2 http://${HOST_SONAR}:9000/api/system/status | jq -r '.status')
echo "s3: $STATUS"
if [ "$STATUS" != "UP" ]; then
  echo "ERROR: SonarQube is not UP. System status was ${STATUS}";
  exit
fi

#############################
echo "Getting new password from Parameter Store."
#############################

RPASSWORD=$(aws ssm get-parameter \
  --name sonar-password \
  --query 'Parameter.Value' \
  --output text 2>/dev/null)

if [ -z ${RPASSWORD} ]; then
  echo "ERROR: Missing value Parameter Store: sonar-password";
  exit
fi

#############################
echo "Changing Sonar default password."
#############################

curl -X POST \
  -u admin:admin \
  -d "login=admin&password=${RPASSWORD}&previousPassword=admin" \
  http://${HOST_SONAR}:9000/api/users/change_password

#############################
echo "Getting Sonar token."
#############################

TOKEN=$(curl \
  --silent \
  -u admin:${RPASSWORD} \
  -d "name=sonar" \
  http://${HOST_SONAR}:9000/api/user_tokens/generate \
  | jq -r '.token')

#############################
echo "Saving Sonar token to Parameter Store."
#############################

aws ssm put-parameter \
  --name sonar-token \
  --value $TOKEN \
  --type String \
  --overwrite > /dev/null
