// MOD-18 Parent Experience — read-only composition for the parent app (ADR-0010).
//
// Note what is absent: spring-boot-starter-data-jpa. This module owns no tables and defines
// no entity, so it reads through spring-jdbc against a documented projection. Pulling JPA in
// would invite someone to map an entity here, and an entity is a claim of ownership this
// module deliberately does not make.
dependencies {
    implementation(project(":guardian-common"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.validation)

    // JdbcTemplate and spring-tx. The DataSource is the tenant-aware one configured in
    // guardian-api, so these queries run under the same RLS context as every other read.
    implementation(rootProject.libs.spring.boot.starter.jdbc)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testRuntimeOnly(rootProject.libs.postgresql)
}
