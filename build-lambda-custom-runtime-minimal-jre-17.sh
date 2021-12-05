#!/bin/sh

# remove a maybe earlier build custom runtime archives
rm runtime-x86.zip
rm runtime-arm.zip

###############
## X86 BUILD ##
###############
# build the docker image which will:
#   1. use the latest Amazon Linux 2 image and install Amazon Corretto 17
#   2. copy the software directory into the Docker container and run the build using Maven, which create an uber jar
#   3. run jdeps to calculate the module dependencies for this uber jar
#   4. feeding the jdeps result into jlink, creating a minimal Java 17 JRE which only contains the necessary modules to run this jar
#   5. create the runtime.zip archive, based on the AWS Lambda custom runtime specification
docker build -f Dockerfile-x86 --progress=plain -t lambda-custom-runtime-minimal-jre-17-x86 .

# extract the runtime.zip from the Docker container and store it locally
docker run --rm --entrypoint cat lambda-custom-runtime-minimal-jre-17-x86 runtime.zip > runtime-x86.zip

###############
## ARM BUILD ##
###############
# build the docker image which will:
#   1. use the latest Amazon Linux 2 image and install Amazon Corretto 17
#   2. for ARM, install the ARM version of aws-lambda-java-runtime-interface-client-2.0.0.jar in our local Maven repo, so that we use this version instead of the official x86 version
#   3. copy the software directory into the Docker container and run the build using Maven, which create an uber jar
#   4. run jdeps to calculate the module dependencies for this uber jar
#   5. feeding the jdeps result into jlink, creating a minimal Java 17 JRE which only contains the necessary modules to run this jar
#   6. create the runtime.zip archive, based on the AWS Lambda custom runtime specification
docker build -f Dockerfile-arm --progress=plain -t lambda-custom-runtime-minimal-jre-17-arm .

# extract the runtime.zip from the Docker container and store it locally
docker run --rm --entrypoint cat lambda-custom-runtime-minimal-jre-17-arm runtime.zip > runtime-arm.zip
