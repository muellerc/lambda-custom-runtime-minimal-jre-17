#!/bin/sh
set -e

# let's remember the projects root directory location
PROJECT_ROOT_DIRECTORY=$(pwd)

# navigate into the infrastructure sub-directory
cd infrastructure

# synthesize the AWS CDK
cdk synth

# deploy the AWS infrastructure
cdk deploy --outputs-file target/outputs.json

# test the Amazon API Gateway endpoint
# we should see an HTTP 200 status code
curl -i $(cat target/outputs.json | jq -r '.LambdaCustomRuntimeMinimalJRE17InfrastructureStack.apiendpoint')/custom-runtime-x86
curl -i $(cat target/outputs.json | jq -r '.LambdaCustomRuntimeMinimalJRE17InfrastructureStack.apiendpoint')/custom-runtime-arm

# navigate back into the projects root directory
cd $(pwd)
