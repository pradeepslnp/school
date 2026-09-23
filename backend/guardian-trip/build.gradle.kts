// MOD-08 Trip Execution. Owns `trips` and `trip_manifests`.
//
// The operational centre: every safety event in MOD-09 is anchored to a trip row this module
// created, and the parent read model (MOD-18) derives journey state from trips joined to
// manifests and boarding events. Until this module existed, nothing in the platform created a
// trip, so those reads had nothing to read — see documentation/06-development/IMPLEMENTATION_STATUS.md.
//
// JDBC, not JPA, matching guardian-absence and guardian-boarding: the tables are few, the
// statements are set-based (generation inserts one row per route per direction in a single
// statement), and an ORM aggregate would be ceremony around them.
dependencies {
    implementation(project(":guardian-common"))
    // BR-TRIP-004: a trip may not start unless the vehicle (BR-FLEET-002) and the crew
    // (BR-STAFF-001/002) are fit to carry children. Both checks are asked of the modules that
    // own them rather than re-implemented here — GetVehicleEligibilityUseCase's Javadoc names
    // MOD-08 as the caller that combines them. The direction is downward (MODULE_MAP.md).
    implementation(project(":guardian-fleet"))
    implementation(project(":guardian-staff"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.validation)
    implementation(rootProject.libs.spring.boot.starter.jdbc)

    testImplementation(rootProject.libs.testcontainers.junit)
    testImplementation(rootProject.libs.testcontainers.postgresql)
    testRuntimeOnly(rootProject.libs.postgresql)
}
