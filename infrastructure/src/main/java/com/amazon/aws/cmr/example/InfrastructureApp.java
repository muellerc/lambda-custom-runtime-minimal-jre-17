package com.amazon.aws.cmr.example;

import software.amazon.awscdk.core.App;

public class InfrastructureApp {
    public static void main(final String[] args) {
        App app = new App();

        new InfrastructureStack(app, "LambdaCustomRuntimeMinimalJRE17InfrastructureStack");

        app.synth();
    }
}
