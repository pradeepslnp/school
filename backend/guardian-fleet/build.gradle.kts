dependencies {
    implementation(project(":guardian-common"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.data.jpa)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.validation)

    // Device credential hashing (Argon2id) — mirrors guardian-identity's SecretHasher.
    // Not a dependency on guardian-identity: devices are a fleet-owned artifact, not a user
    // (MOD-02), so this is its own small port rather than a cross-module coupling for one call.
    implementation(rootProject.libs.spring.security.crypto)
    implementation(rootProject.libs.bouncycastle.provider)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testRuntimeOnly(rootProject.libs.postgresql)
}
