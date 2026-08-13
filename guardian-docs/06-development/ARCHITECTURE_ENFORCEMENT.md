# ARCHITECTURE ENFORCEMENT

**Document tier:** 6 — Development
**Status:** Active

Architecture that is only documented erodes. Every rule below is an **automated test that fails the build**.

Location: `guardian-common/src/test/java/com/guardian/architecture/`.

---

## Layer Dependencies

```java
@AnalyzeClasses(packages = "com.guardian", importOptions = DoNotIncludeTests.class)
class LayerDependencyTest {

    @ArchTest
    static final ArchRule domain_depends_on_nothing =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("..application..", "..infrastructure..", "..interfaces..");

    @ArchTest
    static final ArchRule application_does_not_depend_on_infrastructure =
        noClasses().that().resideInAPackage("..application..")
            .should().dependOnClassesThat().resideInAPackage("..infrastructure..");

    @ArchTest
    static final ArchRule interfaces_do_not_touch_infrastructure =
        noClasses().that().resideInAPackage("..interfaces..")
            .should().dependOnClassesThat().resideInAPackage("..infrastructure..");
}
```

---

## Framework Isolation

The domain must survive a framework change.

```java
@ArchTest
static final ArchRule domain_is_framework_free =
    noClasses().that().resideInAPackage("..domain..")
        .should().dependOnClassesThat().resideInAnyPackage(
            "org.springframework..", "jakarta.persistence..",
            "jakarta.servlet..", "com.fasterxml.jackson..");
```

Also asserted: no domain class carries `@Entity`, `@Service`, `@Component`, or `@Transactional`.

---

## JPA Entities Stay in Infrastructure

```java
@ArchTest
static final ArchRule jpa_entities_confined =
    classes().that().areAnnotatedWith(Entity.class)
        .should().resideInAPackage("..infrastructure.persistence..");

@ArchTest
static final ArchRule entities_never_returned_from_controllers =
    noMethods().that().areDeclaredInClassesThat().resideInAPackage("..interfaces..")
        .should().haveRawReturnType(resideInAPackage("..infrastructure.persistence.."));
```

A JPA entity reaching a client leaks the schema and couples the wire format to the ORM.

---

## Module Boundaries

```java
@ArchTest
static final ArchRule no_module_cycles =
    slices().matching("com.guardian.(*)..").should().beFreeOfCycles();

@ArchTest
static final ArchRule modules_do_not_reach_into_each_others_internals =
    noClasses().that().resideInAPackage("com.guardian.(*)..")
        .should().dependOnClassesThat()
        .resideInAnyPackage("com.guardian.*.infrastructure..",
                            "com.guardian.*.domain..");
```

Cross-module access goes through the owning module's **application layer** ([`MODULE_MAP.md`](../01-product-discovery/MODULE_MAP.md) rule 1). Reaching into another module's repository or domain is the first step to a distributed ball of mud.

---

## Dependency Injection

```java
@ArchTest
static final ArchRule no_field_injection =
    noFields().should().beAnnotatedWith(Autowired.class);

@ArchTest
static final ArchRule dependencies_are_final =
    fields().that().areDeclaredInClassesThat().areAnnotatedWith(Service.class)
        .and().areNotStatic()
        .should().beFinal();
```

Constructor injection only ([`ENGINEERING_PRINCIPLES.md`](../ENGINEERING_PRINCIPLES.md) §5).

---

## Security 🔴

```java
@ArchTest
static final ArchRule every_endpoint_declares_a_permission =
    methods().that().areAnnotatedWith(RequestMapping.class)
        .or().areAnnotatedWith(GetMapping.class)
        .or().areAnnotatedWith(PostMapping.class)
        .or().areAnnotatedWith(PutMapping.class)
        .or().areAnnotatedWith(PatchMapping.class)
        .or().areAnnotatedWith(DeleteMapping.class)
        .should().beAnnotatedWith(RequiresPermission.class)
        .orShould().beAnnotatedWith(PublicEndpoint.class);
```

**Deny by default** (BR-IAM-002 🔴). An endpoint with no declared permission fails the build rather than shipping unprotected.

A companion test asserts every `@RequiresPermission` value exists in [`PERMISSION_MATRIX.md`](../01-product-discovery/PERMISSION_MATRIX.md), parsed from the document itself — so the code cannot drift from the matrix.

```java
@ArchTest
static final ArchRule no_raw_sql_string_concatenation =
    noClasses().should().callMethod(Statement.class, "executeQuery", String.class);
```

---

## Tenant Isolation 🔴

```java
@ArchTest
static final ArchRule no_session_scoped_tenant_setting =
    noClasses().should().callMethodWhere(target(nameMatching(".*"))
        .and(declaredIn(JdbcTemplate.class)))
        .andShould().containStringLiteral("SET app.tenant_id");
```

Only `SET LOCAL` is permitted. A session-scoped `SET` survives a pooled connection into the next request — a silent cross-tenant leak with no error and no log entry ([`RLS_POLICIES.md`](../03-database/RLS_POLICIES.md)).

A migration test additionally asserts **every table with a `tenant_id` column has RLS enabled and forced**, so a new table cannot ship without a policy.

---

## Integration Boundaries

```java
@ArchTest
static final ArchRule no_provider_sdks_in_domain_or_application =
    noClasses().that().resideInAnyPackage("..domain..", "..application..")
        .should().dependOnClassesThat().resideInAnyPackage(
            "com.google.firebase..", "com.twilio..", "software.amazon.awssdk..");
```

Providers live behind ports (ADR-0004, ADR-0005). A new vendor is a new adapter, never a change to a use case.

---

## Localisation

```java
@ArchTest
static final ArchRule no_user_facing_string_literals =
    noClasses().that().resideInAnyPackage("..interfaces..", "..domain..")
        .should().callConstructorWhere(
            owner(assignableTo(RuntimeException.class))
            .and(rawParameterTypes(String.class)));
```

All user-facing text is a localised resource key (BR-CFG-005). Exceptions carry an `ErrorCode`, not a message.

---

## Append-Only Tables 🔴

Verified against the live schema in an integration test rather than by static analysis:

```java
@Test
void append_only_tables_reject_mutation() {
    for (String table : List.of("audit_records", "boarding_events", "handovers")) {
        assertThatThrownBy(() -> jdbc.update("UPDATE " + table + " SET tenant_id = tenant_id"))
            .hasMessageContaining("append-only");
        assertThatThrownBy(() -> jdbc.update("DELETE FROM " + table))
            .hasMessageContaining("append-only");
    }
}

@Test
void application_role_lacks_bypass_rls() { … }
```

---

## Traceability

Run in CI against the documentation itself:

| Check | Rule |
|---|---|
| Every `@RequiresPermission` exists in the permission matrix | BR-IAM-002 |
| Every business rule ID has ≥1 test referencing it | [`DOCUMENT_HIERARCHY.md`](../00-governance/DOCUMENT_HIERARCHY.md) invariant 2 |
| Every `R1` feature ID appears in an API doc and a test case | invariant 1 |
| Every error code returned exists in the error catalog | [`ERROR_CATALOG.md`](../04-api/ERROR_CATALOG.md) |
| No documentation link points at a missing path | invariant 4 |

Business rule references use an annotation, making them greppable and countable:

```java
@BusinessRule("BR-SAFE-001")
@Test
void trip_cannot_close_with_unaccounted_student() { … }
```

---

## Flutter Enforcement

```dart
// test/architecture_test.dart
test('guardian_core domain does not depend on Flutter widgets', () { … });
test('no widget contains a hardcoded user-facing string', () { … });
test('no business rule is evaluated inside a widget', () { … });
```

Plus `flutter analyze` with a strict lint set ([`CODING_STANDARDS_FLUTTER.md`](CODING_STANDARDS_FLUTTER.md)).

---

## When a Rule Blocks Legitimate Work

Three options, in order of preference:

1. **Restructure the code** — usually the rule is right.
2. **Narrow the rule** with a documented, reviewed exception naming the specific class and reason.
3. **Change the rule**, via an ADR amending the principle behind it.

**Never** disable a test to unblock a merge. A disabled architecture test is an architecture that has already eroded.
