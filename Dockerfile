FROM amazonlinux:2.0.20211005.0 AS packer

# Add the Amazon Corretto repository
RUN rpm --import https://yum.corretto.aws/corretto.key
RUN curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo

# Update the packages and install Amazon Corretto 17, Maven and Zip
RUN yum -y update \
    && yum install -y java-17-amazon-corretto-devel maven zip


# Copy the software folder to the image and build the function
ADD software software
WORKDIR /software/example-function
RUN mvn clean package


# Find JDK module dependencies dynamically from our uber jar
RUN jdeps \
    # dont worry about missing modules
    --ignore-missing-deps \
    # suppress any warnings printed to console
    -q \
    # java release version targeting
    --multi-release 17 \
    # output the dependencies at end of run
    --print-module-deps \
    # pipe the result of running jdeps on the function jar to file
    target/function.jar > jre-deps.info

# Create a slim Java 17 JRE which only contains the required modules to run this function
RUN jlink --verbose \
    --compress 2 \
    --strip-java-debug-attributes \
    --no-header-files \
    --no-man-pages \
    --output /jre17-slim \
    --add-modules $(cat jre-deps.info)


# Use Javas Application Class Data Sharing feature to precompile JDK and our function.jar file
# it creates the file /jre17-slim/lib/server/classes.jsa
RUN /jre17-slim/bin/java -Xshare:dump -Xbootclasspath/a:/software/example-function/target/function.jar -version


# Package everything together into a custom runtime archive
WORKDIR /

ADD bootstrap bootstrap
RUN chmod 755 bootstrap
RUN cp /software/example-function/target/function.jar function.jar
RUN zip -r runtime.zip \
    bootstrap \
    function.jar \
    /jre17-slim
