// MOD-14 Absence. Owns the `absences` table.
//
// Writes live here rather than in MOD-18: ADR-0010 makes the parent read module read-only, so
// declaring and cancelling an absence stays with the module that owns the record.
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
