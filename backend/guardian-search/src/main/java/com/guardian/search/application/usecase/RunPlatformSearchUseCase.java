package com.guardian.search.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.AuditPort;
import com.guardian.common.audit.AuditRecord;
import com.guardian.common.audit.DataAccessPort;
import com.guardian.common.audit.DataAccessRecord;
import com.guardian.common.error.PermissionDeniedException;
import com.guardian.common.security.CallerAccess;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantId;
import com.guardian.common.tenant.TenantScopedTransaction;
import com.guardian.search.application.port.PlatformSearchReadModel;
import com.guardian.search.application.result.SearchGroup;
import com.guardian.search.application.result.SearchResults;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import com.guardian.search.domain.SearchResultType;
import com.guardian.tenancy.application.usecase.ListOrganizationsUseCase;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;

/**
 * A platform operator's global search across every organization at once — feature SRC-001,
 * ADR-0018.
 *
 * <p><strong>This is a platform-operations path across the tenant boundary</strong> (BR-TEN-004
 * 🔴), so three things hold together:
 *
 * <ul>
 *   <li><em>Permissioned.</em> Only a caller whose current scope is {@code PLATFORM}, held by a
 *       {@code SUPER_ADMIN}, reaches it; anyone else is refused, not quietly narrowed. Each kind of
 *       record still requires its own view permission, as in {@link RunGlobalSearchUseCase}.
 *   <li><em>Audited per organization.</em> Every organization whose records appear in the result
 *       receives a {@code PLATFORM_CROSS_ORG_SEARCH} audit record in its own trail — where someone
 *       asking "who outside our organization looked at our records?" will look (BR-AUD-005).
 *       Organizations that only matched by name are the organizations list, which is not their
 *       data.
 *   <li><em>Every student recorded</em> (BR-IAM-012 🔴), in the data-access log of the organization
 *       that student belongs to.
 * </ul>
 *
 * <p><strong>Transactions are programmatic, not {@code @Transactional}.</strong> Audit and access
 * records are tenant-scoped, and a record for one organization can only be written on a connection
 * bound to that organization. So the read runs in one short transaction under the operator's home
 * tenant, and each organization's records are written in a transaction of their own. Every record
 * is written before results are returned: if any write fails, the request fails and nothing is
 * shown.
 */
@Service
@BusinessRule({"BR-TEN-004", "BR-IAM-012"})
public class RunPlatformSearchUseCase {

  private static final String PLATFORM_ROLE = "SUPER_ADMIN";
  private static final String PURPOSE = "GLOBAL_SEARCH";
  private static final String AUDIT_ACTION = "PLATFORM_CROSS_ORG_SEARCH";

  private final PlatformSearchReadModel readModel;
  private final ListOrganizationsUseCase listOrganizations;
  private final DataAccessPort dataAccessPort;
  private final AuditPort auditPort;
  private final TenantScopedTransaction tenantScoped;

  public RunPlatformSearchUseCase(
      PlatformSearchReadModel readModel,
      ListOrganizationsUseCase listOrganizations,
      DataAccessPort dataAccessPort,
      AuditPort auditPort,
      TenantScopedTransaction tenantScoped) {
    this.readModel = readModel;
    this.listOrganizations = listOrganizations;
    this.dataAccessPort = dataAccessPort;
    this.auditPort = auditPort;
    this.tenantScoped = tenantScoped;
  }

  public SearchResults execute(SearchQuery query, CallerAccess access, CurrentActor actor) {
    if (!access.scope().platformWide()
        || !PLATFORM_ROLE.equals(actor.role())
        || actor.homeTenantId() == null) {
      throw new PermissionDeniedException(
          "Searching across organizations requires the platform scope");
    }

    TenantId home = TenantId.of(actor.homeTenantId());
    List<SearchGroup> groups = tenantScoped.execute(home, () -> search(query, access, actor));

    recordCrossings(groups, actor);
    return new SearchResults(query.text(), groups);
  }

  private List<SearchGroup> search(SearchQuery query, CallerAccess access, CurrentActor actor) {
    int fetch = SearchGrouping.FETCH_SIZE;
    List<SearchGroup> groups = new ArrayList<>();

    if (access.holds("PERM-STUDENT-VIEW")) {
      SearchGrouping.add(groups, SearchResultType.STUDENT, readModel.students(query, fetch));
      SearchGrouping.add(groups, SearchResultType.GUARDIAN, readModel.guardians(query, fetch));
    }
    if (access.holds("PERM-STAFF-MANAGE")) {
      SearchGrouping.add(groups, SearchResultType.STAFF, readModel.staff(query, fetch));
    }
    if (access.holds("PERM-VEHICLE-VIEW")) {
      SearchGrouping.add(groups, SearchResultType.VEHICLE, readModel.vehicles(query, fetch));
    }
    if (access.holds("PERM-ROUTE-VIEW")) {
      SearchGrouping.add(groups, SearchResultType.ROUTE, readModel.routes(query, fetch));
    }
    if (access.holds("PERM-USER-VIEW")) {
      SearchGrouping.add(
          groups, SearchResultType.USER, readModel.administrativeUsers(query, fetch));
    }
    if (access.holds("PERM-SCHOOL-VIEW")) {
      SearchGrouping.add(groups, SearchResultType.SCHOOL, readModel.schools(query, fetch));
    }
    if (access.holds("PERM-ORG-VIEW")) {
      SearchGrouping.add(
          groups,
          SearchResultType.ORGANIZATION,
          SearchGrouping.platformOrganizations(listOrganizations, query, actor.role(), fetch));
    }
    return groups;
  }

  /** One audit record per organization shown, and one access record per student, in its trail. */
  private void recordCrossings(List<SearchGroup> groups, CurrentActor actor) {
    Map<UUID, Set<UUID>> studentsByOrganization = new LinkedHashMap<>();
    Set<UUID> distinctStudents = new LinkedHashSet<>();

    for (SearchGroup group : groups) {
      for (SearchHit hit : group.hits()) {
        if (hit.type() == SearchResultType.ORGANIZATION || hit.organizationId() == null) {
          continue;
        }
        Set<UUID> students =
            studentsByOrganization.computeIfAbsent(
                hit.organizationId(), id -> new LinkedHashSet<>());
        if (hit.type() == SearchResultType.STUDENT) {
          students.add(hit.id());
          distinctStudents.add(hit.id());
        }
        if (hit.relatedStudentId() != null) {
          students.add(hit.relatedStudentId());
          distinctStudents.add(hit.relatedStudentId());
        }
      }
    }

    int count = distinctStudents.size();
    Instant now = Instant.now();
    for (Map.Entry<UUID, Set<UUID>> entry : studentsByOrganization.entrySet()) {
      TenantId organization = TenantId.of(entry.getKey());
      tenantScoped.execute(
          organization,
          () -> {
            auditPort.record(
                AuditRecord.builder()
                    .tenantId(organization)
                    .actor(actor.userId(), AuditRecord.ActorType.PLATFORM_OPERATOR, actor.role())
                    .action(AUDIT_ACTION)
                    .subject("ORGANIZATION", organization.value())
                    .source(AuditRecord.Source.PLATFORM_OPS)
                    // The query text is deliberately not recorded: it is often a child's name, and
                    // audit records carry no unnecessary child personal data (BR-AUD-006). The
                    // data-access records below name exactly which students were shown.
                    .reason("Platform-wide search showed this organization's records")
                    .occurredAt(now)
                    .build());
            if (!entry.getValue().isEmpty()) {
              dataAccessPort.recordAll(
                  entry.getValue().stream()
                      .map(
                          studentId ->
                              DataAccessRecord.listed(
                                  organization,
                                  actor.userId(),
                                  actor.role(),
                                  studentId,
                                  count,
                                  PURPOSE))
                      .toList());
            }
            return null;
          });
    }
  }
}
