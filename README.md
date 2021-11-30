# AWS Lambda Custom Runtime based on minimal Java 17 JRE
An AWS Lambda custom runtime to enable Java 17 support on a minimalistic JRE, which only includes the Java modules required by this function.

## Getting started

Download or clone the repository.

To install prerequisite software:

1. Install [AWS CDK](https://docs.aws.amazon.com/cdk/latest/guide/getting_started.html)
2. Install [Docker](https://docs.docker.com/get-docker/)
3. Build and package the AWS Lambda function and create the AWS Lambda custom runtime using Docker:

```bash
./build-lambda-custom-runtime-minimal-jre-17.sh
```

The script does the following tasks:  
  a) use the latest Amazon Linux 2 image and install Amazon Corretto 17
  b) copy the software directory into the Docker container and run the build using Maven, which create an uber jar
  c) run jdeps to calculate the Java module dependencies for this uber jar
  d) feeding the jdeps output into jlink, creating a minimal Java 17 JRE which only contains the necessary modules to run this jar
  e) create the runtime.zip archive, based on the AWS Lambda custom runtime specification
  f) extracts the runtime.zip archive from the Docker image into your project root directory

4. Provision the AWS infrastructure (mainly Amazon API Gateway, AWS Lambda and Amazon DynamoDB) using AWS CDK:

```bash
./provision-infrastructure.sh
```

The API Gateway endpoint URL is displayed in the output and saved in the file `infrastructure/target/outputs.json`. The contents are similar to:

```
{
  "LambdaCustomRuntimeMinimalJRE17InfrastructureStack": {
    "apiendpoint": "https://<API_ID>.execute-api.<AWS_REGION>.amazonaws.com"
  }
}
```


## Using Artillery to load test the changes

First, install prerequisites:

1. Install [jq](https://stedolan.github.io/jq/) and [Artillery Core](https://artillery.io/docs/guides/getting-started/installing-artillery.html)
2. Run the following two scripts from the `/infrastructure` directory:

```bash
artillery run -t $(cat target/outputs.json | jq -r '.LambdaCustomRuntimeMinimalJRE17InfrastructureStack.apiendpoint') -v '{ "url": "/custom-runtime" }' loadtest.yml
```


### Check results in Amazon CloudWatch Insights

1. Navigate to Amazon **[CloudWatch Logs Insights](https://console.aws.amazon.com/cloudwatch/home?#logsV2:logs-insights)**.
2.Select the log group `/aws/lambda/lambda-custom-runtime-minimal-jre-17` from the drop-down list
3. Copy the following query and choose **Run query**:

```
filter @type = "REPORT"
| parse @log /\d+:\/aws\/lambda\/lambda-(?<function>.+)/
| stats
count(*) as invocations,
pct(@duration, 0) as p0,
pct(@duration, 25) as p25,
pct(@duration, 50) as p50,
pct(@duration, 75) as p75,
pct(@duration, 90) as p90,
pct(@duration, 95) as p95,
pct(@duration, 99) as p99,
pct(@duration, 100) as p100
group by function, ispresent(@initDuration) as coldstart
| sort by function, coldstart
```

![AWS Console](docs/insights-query.png)

You see results similar to:

![Resuts](docs/results.png)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.












## Usage

### with CDK

- Download [java17layer.zip](https://github.com/msailes/lambda-java17-layer/releases/download/v0.0.1-alpha/java17layer.zip)
- Create a Lambda layer using Code.fromAsset `java17layer.zip`
- Note you might need to adjust the path for your own project structure

```java 
LayerVersion java17layer = new LayerVersion(this, "Java17Layer", LayerVersionProps.builder()
        .layerVersionName("Java17Layer")
        .description("Java 17")
        .compatibleRuntimes(Arrays.asList(Runtime.PROVIDED_AL2))
        .code(Code.fromAsset("java17layer.zip"))
        .build());
```

- Create a function using the PROVIDED_AL2 runtime.
- Add this layer to your function.

```java
Function exampleWithLayer = new Function(this, "ExampleWithLayer", FunctionProps.builder()
        .functionName("example-with-layer")
        .description("example-with-layer")
        .handler("example.HelloWorld::handleRequest")
        .runtime(Runtime.PROVIDED_AL2)
        .code(Code.fromAsset("../software/ExampleFunction/target/example.jar"))
        .memorySize(512)
        .logRetention(RetentionDays.ONE_WEEK)
        .layers(singletonList(java17layer))
        .build());
```

## Layer Details

### Java 17 

A custom JRE is created to reduce final file size. Lambda has a 250MB unzipped file size limit.

[Dockerfile](_Dockerfile) describes how the JRE is built.

### JVM Settings

The following JVM settings are added by default.

```
--add-opens java.base/java.util=ALL-UNNAMED 
-XX:+TieredCompilation -XX:TieredStopAtLevel=1 
-Xshare:on
```

Further suggestions welcomed

### Java Class Path

```
aws-lambda-java-runtime-interface-client-1.1.0.jar
aws-lambda-java-core-1.2.1.jar
aws-lambda-java-serialization-1.0.0.jar
$LAMBDA_TASK_ROOT
$LAMBDA_TASK_ROOT/*
$LAMBDA_TASK_ROOT/lib/*
```

## Build the layer zip yourself

### Requirements

- Docker

### Steps

- Run `build-jre.sh` to build the minimal Java 17 runtime
- Run `make-layer.sh` to package the runtime, dependencies and bootstrap as a zip

