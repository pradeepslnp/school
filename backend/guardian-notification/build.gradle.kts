// MOD-12 Notification. Owns the `notifications` table.
//
// Scope here is the durable record a parent scrolls back through (P-08). Dispatch — templates,
// channels, provider adapters, delivery attempts (ADR-0005) — is the other half of this module
// and arrives with the notification engine.
dependencies {
    implementation(project(":guardian-common"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.jdbc)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testRuntimeOnly(rootProject.libs.postgresql)
}
