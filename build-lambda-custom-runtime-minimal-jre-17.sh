#!/bin/sh

# remove a maybe earlier build custom runtime archive
rm runtime.zip

# build the docker image which will:
#   1. use the latest Amazon Linux 2 image and install Amazon Corretto 17
#   2. copy the software directory into the Docker container and run the build using Maven, which create an uber jar
#   3. run jdeps to calculate the module dependencies for this uber jar
#   4. feeding the jdeps result into jlink, creating a minimal Java 17 JRE which only contains the necessary modules to run this jar
#   5. create the runtime.zip archive, based on the AWS Lambda custom runtime specification
docker build --progress=plain -t lambda-custom-runtime-minimal-jre-17 .

# extract the runtime.zip from the Docker container and store it locally
docker run --rm --entrypoint cat lambda-custom-runtime-minimal-jre-17 runtime.zip > runtime.zip
