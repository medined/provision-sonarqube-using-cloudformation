#!/bin/bash

#############################
echo "Getting IP address of SonarQube server."
#############################

SONARIP=$(aws cloudformation list-exports \
  --query "Exports[?Name==\`sonar:PublicIp\`].Value" \
  --output text)

if [ -z ${SONARIP} ]; then
  echo "ERROR: Missing CloudFormat export: sonar:PublicIp";
  exit
fi

#############################
echo "Getting new token from Parameter Store."
#############################

TOKEN=$(aws ssm get-parameter \
  --name sonar-token \
  --query 'Parameter.Value' \
  --output text 2>/dev/null)

if [ -z ${TOKEN} ]; then
  echo "ERROR: Missing value Parameter Store: sonar-token";
  exit
fi

#############################
echo "Sending info to SonarQube."
#############################

mvn \
  clean \
  install \
  jacoco:report \
  sonar:sonar \
  -Dsonar.host.url=http://${SONARIP}:9000 \
  -Dsonar.login=${TOKEN}
