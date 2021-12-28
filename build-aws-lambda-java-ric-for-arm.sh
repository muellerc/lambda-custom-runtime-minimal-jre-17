#!/bin/bash

set -euo pipefail

# remove a potential earlier cloned aws-lambda-java-libs repository
rm -rf aws-lambda-java-libs

git clone https://github.com/aws/aws-lambda-java-libs.git
cd aws-lambda-java-libs

# Make sure we use a know version, as we don't have a Git tag we can use
git reset --hard 99f02cd416dd96f8cc915f0fa2e4534e92a574cc

# Compile the Lambda Java RIC
cd aws-lambda-java-runtime-interface-client
mvn clean compile

# Build the native aws-lambda-runtime-interface-client.glibc.so and aws-lambda-runtime-interface-client.musl.so
# file for ARM
cd src/main/jni
docker build --platform=linux/arm64/v8 -f Dockerfile.glibc --build-arg CURL_VERSION=7.77.0 -t lambda-java-jni-lib-glibc-arm .
docker build --platform=linux/arm64/v8 -f Dockerfile.musl --build-arg CURL_VERSION=7.77.0 -t lambda-java-jni-lib-musl-arm .

# Extract the *.so files from the container and place them in the target/classes directory
cd ../../..
docker run --rm --entrypoint /bin/cat lambda-java-jni-lib-glibc-arm /src/aws-lambda-runtime-interface-client.so > target/classes/aws-lambda-runtime-interface-client.glibc.so
docker run --rm --entrypoint /bin/cat lambda-java-jni-lib-musl-arm /src/aws-lambda-runtime-interface-client.so > target/classes/aws-lambda-runtime-interface-client.musl.so

# package aws-lambda-java-runtime-interface-client-2.0.0.jar with the ARM native *.so files
mvn package -DskipTests -Dmaven.antrun.skip=true
