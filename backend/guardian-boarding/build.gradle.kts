// MOD-09 Boarding & Attendance — this module currently owns only
// `handover_verification_codes` (screen P-12's code issuance).
//
// The rest of MOD-09 per MODULE_MAP.md — boarding/alighting events, handover redemption,
// trip-close reconciliation — is unbuilt. It belongs to the driver/attendant app's write
// path, which this codebase has not implemented yet. Naming the module MOD-09 now, rather
// than inventing a narrower name, is deliberate: when that work lands it extends this
// module instead of creating a second one that also claims to own handovers.
dependencies {
    implementation(project(":guardian-common"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.validation)
    implementation(rootProject.libs.spring.boot.starter.jdbc)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testRuntimeOnly(rootProject.libs.postgresql)
}
