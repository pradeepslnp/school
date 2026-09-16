plugins {
    alias(libs.plugins.spring.boot)
}

dependencies {
    implementation(project(":guardian-common"))
    implementation(project(":guardian-tenancy"))
    implementation(project(":guardian-identity"))
    implementation(project(":guardian-student"))
    implementation(project(":guardian-guardian"))
    implementation(project(":guardian-fleet"))
    implementation(project(":guardian-staff"))
    implementation(project(":guardian-routes"))
    implementation(project(":guardian-absence"))
    implementation(project(":guardian-notification"))
    implementation(project(":guardian-boarding"))
    // MOD-18, read-only (ADR-0010). Depends downward on nothing here — it reads the schema,
    // not other modules' Java.
    implementation(project(":guardian-parent"))
    // MOD-19, read-only (ADR-0017). Reads the schema through its own projection, like MOD-18.
    implementation(project(":guardian-search"))

    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.data.jpa)
    implementation(rootProject.libs.spring.boot.starter.validation)

    // Tenant context is resolved from the authenticated principal, never from the request
    // (SecurityContextTenantResolver, ADR-0006).
    implementation(rootProject.libs.spring.boot.starter.security)

    implementation(rootProject.libs.flyway.core)
    runtimeOnly(rootProject.libs.flyway.postgresql)
    runtimeOnly(rootProject.libs.postgresql)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testImplementation(rootProject.libs.classgraph)
    testImplementation(rootProject.libs.spring.security.test)
}
