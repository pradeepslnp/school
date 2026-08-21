// Resolves the Java 21 toolchain automatically when the machine does not have one.
//
// The build pins Java 21 (build.gradle.kts) while developer machines and CI images carry
// whatever JDK they happen to have. Without this, a contributor with only a newer JDK gets
// "No matching toolchain" and has to hand-install a second JDK before their first build.
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "guardian-platform"

include(
    "guardian-common",
    "guardian-tenancy",
    "guardian-identity",
    // MOD-03. Students, classes, and enrolment — the source of truth for who exists. Does not
    // own transport assignment (MOD-07).
    "guardian-student",
    // MOD-04. Guardians, links, and authorised pickup persons — owns "may this adult collect
    // this child?".
    "guardian-guardian",
    // MOD-05. Vehicles, vehicle documents, and GPS devices.
    "guardian-fleet",
    // MOD-06. Drivers and attendants, their credentials and verification, and duty assignment.
    "guardian-staff",
    // MOD-07. Routes, stops, and student route assignments.
    "guardian-routes",
    // MOD-14 and MOD-12. Both write tables the parent app posts to; ADR-0010 keeps writes with
    // the module that owns the record rather than in the read module below.
    "guardian-absence",
    "guardian-notification",
    // MOD-09, minimal slice (code issuance only — see guardian-boarding/build.gradle.kts).
    "guardian-boarding",
    // MOD-18. Read-only composition for the parent app; owns no tables (ADR-0010).
    "guardian-parent",
    "guardian-api",
)
