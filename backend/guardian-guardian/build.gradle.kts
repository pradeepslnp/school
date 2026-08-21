// MOD-04 Guardian Management. Owns guardians, guardian_student_links, authorised_pickup_persons
// and custody_restrictions.
//
// Owns the answer to "may this adult collect this child?" — consumed by MOD-09 at handover.
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
