// MOD-19 Search — read-only global search for the admin console (ADR-0017).
//
// The same shape as MOD-18 (ADR-0010): owns no tables, defines no entity, and reads one
// documented projection through spring-jdbc. The DataSource is the tenant-aware one configured in
// guardian-api, so every query runs under the same row-level security context as any other read.
//
// guardian-tenancy is the one module it calls, and only for organizations: a platform operator's
// organization list crosses tenants, and that path has exactly one gated entry point
// (ListOrganizationsUseCase), which search reuses rather than duplicates.
dependencies {
    implementation(project(":guardian-common"))
    implementation(project(":guardian-tenancy"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.web)

    // JdbcTemplate and spring-tx — see MOD-18's build file for why not JPA.
    implementation(rootProject.libs.spring.boot.starter.jdbc)
}
