package com.amazon.aws.cmr.example;

import software.amazon.awscdk.core.CfnOutput;
import software.amazon.awscdk.core.CfnOutputProps;
import software.amazon.awscdk.core.Construct;
import software.amazon.awscdk.core.Duration;
import software.amazon.awscdk.core.Stack;
import software.amazon.awscdk.core.StackProps;
import software.amazon.awscdk.services.apigatewayv2.AddRoutesOptions;
import software.amazon.awscdk.services.apigatewayv2.HttpApi;
import software.amazon.awscdk.services.apigatewayv2.HttpApiProps;
import software.amazon.awscdk.services.apigatewayv2.HttpMethod;
import software.amazon.awscdk.services.apigatewayv2.PayloadFormatVersion;
import software.amazon.awscdk.services.apigatewayv2.integrations.LambdaProxyIntegration;
import software.amazon.awscdk.services.apigatewayv2.integrations.LambdaProxyIntegrationProps;
import software.amazon.awscdk.services.dynamodb.Attribute;
import software.amazon.awscdk.services.dynamodb.AttributeType;
import software.amazon.awscdk.services.dynamodb.BillingMode;
import software.amazon.awscdk.services.dynamodb.Table;
import software.amazon.awscdk.services.dynamodb.TableProps;
import software.amazon.awscdk.services.lambda.*;
import software.amazon.awscdk.services.lambda.Runtime;
import software.amazon.awscdk.services.logs.RetentionDays;

import java.util.HashMap;
import java.util.Map;

import static java.util.Collections.singletonList;

public class InfrastructureStack extends Stack {
    public InfrastructureStack(final Construct scope, final String id) {
        this(scope, id, null);
    }

    public InfrastructureStack(final Construct scope, final String id, final StackProps props) {
        super(scope, id, props);

        Table exampleTable = new Table(this, "ExampleTable", TableProps.builder()
                .partitionKey(Attribute.builder()
                        .type(AttributeType.STRING)
                        .name("id").build())
                .billingMode(BillingMode.PAY_PER_REQUEST)
                .build());

        Function exampleCustomRuntime = new Function(this, "LambdaCustomRuntimeMinimalJRE17", FunctionProps.builder()
                .functionName("lambda-custom-runtime-minimal-jre-17")
                .description("lambda-custom-runtime-minimal-jre-17")
                .handler("com.amazon.aws.cmr.example.ExampleDynamoDbHandler::handleRequest")
                .runtime(Runtime.PROVIDED_AL2)
                .architecture(Architecture.X86_64)
                .code(Code.fromAsset("../runtime.zip"))
                .memorySize(512)
                .environment(mapOf("TABLE_NAME", exampleTable.getTableName()))
                .timeout(Duration.seconds(20))
                .logRetention(RetentionDays.ONE_WEEK)
                .build());

        Function exampleCustomRuntimeArm = new Function(this, "LambdaCustomRuntimeMinimalJRE17Arm", FunctionProps.builder()
                .functionName("lambda-custom-runtime-minimal-jre-17-arm")
                .description("lambda-custom-runtime-minimal-jre-17-arm")
                .handler("com.amazon.aws.cmr.example.ExampleDynamoDbHandler::handleRequest")
                .runtime(Runtime.PROVIDED_AL2)
                .architecture(Architecture.ARM_64)
                .code(Code.fromAsset("../runtime-arm.zip"))
                .memorySize(512)
                .environment(mapOf("TABLE_NAME", exampleTable.getTableName()))
                .timeout(Duration.seconds(20))
                .logRetention(RetentionDays.ONE_WEEK)
                .build());

        exampleTable.grantWriteData(exampleCustomRuntimeArm);

        HttpApi httpApi = new HttpApi(this, "ExampleApi", HttpApiProps.builder()
                .apiName("ExampleApi")
                .build());

        httpApi.addRoutes(AddRoutesOptions.builder()
                .path("/custom-runtime")
                .methods(singletonList(HttpMethod.GET))
                .integration(new LambdaProxyIntegration(LambdaProxyIntegrationProps.builder()
                        .handler(exampleCustomRuntime)
                        .payloadFormatVersion(PayloadFormatVersion.VERSION_2_0)
                        .build()))
                .build());

        httpApi.addRoutes(AddRoutesOptions.builder()
                .path("/custom-runtime-arm")
                .methods(singletonList(HttpMethod.GET))
                .integration(new LambdaProxyIntegration(LambdaProxyIntegrationProps.builder()
                        .handler(exampleCustomRuntimeArm)
                        .payloadFormatVersion(PayloadFormatVersion.VERSION_2_0)
                        .build()))
                .build());

        new CfnOutput(this, "api-endpoint", CfnOutputProps.builder()
                .value(httpApi.getApiEndpoint())
                .build());
    }

    private Map<String, String> mapOf(String... keyValues) {
        Map<String, String> map = new HashMap<>(keyValues.length/2);
        for (int i = 0; i < keyValues.length; i++) {
            if(i % 2 == 0) {
                map.put(keyValues[i], keyValues[i + 1]);
            }
        }
        return map;
    }
}
