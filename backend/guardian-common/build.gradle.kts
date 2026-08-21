dependencies {
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.validation)

    // TransactionTemplate for TenantScopedTransaction. The jdbc starter, not data-jpa: this
    // module must stay usable by guardian-parent (ADR-0010, which owns no entity) and by
    // guardian-tenancy/guardian-identity, which already bring their own JPA starter — pulling
    // JPA in here would be a dependency this module has no use for itself.
    implementation(rootProject.libs.spring.boot.starter.jdbc)
}
