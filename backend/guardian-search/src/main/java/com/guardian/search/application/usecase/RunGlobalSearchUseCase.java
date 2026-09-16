package com.guardian.search.application.usecase;

import com.guardian.common.BusinessRule;
import com.guardian.common.audit.DataAccessPort;
import com.guardian.common.audit.DataAccessRecord;
import com.guardian.common.security.AccessScope;
import com.guardian.common.security.CallerAccess;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.tenant.TenantContext;
import com.guardian.common.tenant.TenantId;
import com.guardian.search.application.port.SearchReadModel;
import com.guardian.search.application.result.SearchGroup;
import com.guardian.search.application.result.SearchResults;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import com.guardian.search.domain.SearchResultType;
import com.guardian.tenancy.application.usecase.ListOrganizationsUseCase;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The console's global search within one organization — feature SRC-001, ADR-0017. A platform
 * operator's search across organizations is {@link RunPlatformSearchUseCase} (ADR-0018).
 *
 * <p><strong>Holding {@code PERM-SEARCH-QUERY} opens the search; it shows nothing by
 * itself.</strong> Each kind of record is searched only when the caller holds that kind's own view
 * permission — the same permission its own screen and endpoint require — so search can never show a
 * record the caller could not already open (BR-IAM-002). Within a kind, school scope is applied
 * inside the projection (BR-IAM-006); an empty scope searches no school-bound kind at all.
 *
 * <p><strong>Every student shown is recorded</strong> (BR-IAM-012 🔴): each student result, and the
 * linked child shown beside a guardian, writes a {@code LIST} data-access record in this
 * transaction. Only what is returned is recorded — rows fetched to learn whether there are more are
 * never shown and never logged. Guardians cannot reach this use case ({@code PERM-SEARCH-QUERY} is
 * not theirs), so every read here is a non-guardian read.
 *
 * <p>Not read-only for the same reason as {@code GetStudentUseCase}: a read whose access record
 * cannot be stored does not happen at all.
 */
@Service
@BusinessRule({"BR-IAM-002", "BR-IAM-006", "BR-IAM-012", "BR-TEN-004"})
public class RunGlobalSearchUseCase {

  private static final String PURPOSE = "GLOBAL_SEARCH";
  private static final String PLATFORM_ROLE = "SUPER_ADMIN";

  private final SearchReadModel readModel;
  private final ListOrganizationsUseCase listOrganizations;
  private final DataAccessPort dataAccessPort;

  public RunGlobalSearchUseCase(
      SearchReadModel readModel,
      ListOrganizationsUseCase listOrganizations,
      DataAccessPort dataAccessPort) {
    this.readModel = readModel;
    this.listOrganizations = listOrganizations;
    this.dataAccessPort = dataAccessPort;
  }

  @Transactional
  public SearchResults execute(SearchQuery query, CallerAccess access, CurrentActor actor) {
    AccessScope scope = access.scope();
    int fetch = SearchGrouping.FETCH_SIZE;
    List<SearchGroup> groups = new ArrayList<>();

    if (!scope.isEmpty()) {
      if (access.holds("PERM-STUDENT-VIEW")) {
        SearchGrouping.add(
            groups, SearchResultType.STUDENT, readModel.students(query, scope, fetch));
        // Parents are shown with a child, and are visible exactly where that child is — the
        // guardian list endpoint is gated by the same permission.
        SearchGrouping.add(
            groups, SearchResultType.GUARDIAN, readModel.guardians(query, scope, fetch));
      }
      if (access.holds("PERM-STAFF-MANAGE")) {
        SearchGrouping.add(groups, SearchResultType.STAFF, readModel.staff(query, scope, fetch));
      }
      if (access.holds("PERM-VEHICLE-VIEW")) {
        SearchGrouping.add(
            groups, SearchResultType.VEHICLE, readModel.vehicles(query, scope, fetch));
      }
      if (access.holds("PERM-ROUTE-VIEW")) {
        SearchGrouping.add(groups, SearchResultType.ROUTE, readModel.routes(query, scope, fetch));
      }
      if (access.holds("PERM-USER-VIEW")) {
        SearchGrouping.add(
            groups, SearchResultType.USER, readModel.administrativeUsers(query, scope, fetch));
      }
      if (access.holds("PERM-SCHOOL-VIEW")) {
        SearchGrouping.add(groups, SearchResultType.SCHOOL, readModel.schools(query, scope, fetch));
      }
    }
    if (access.holds("PERM-ORG-VIEW")) {
      SearchGrouping.add(
          groups,
          SearchResultType.ORGANIZATION,
          PLATFORM_ROLE.equals(actor.role())
              ? SearchGrouping.platformOrganizations(listOrganizations, query, actor.role(), fetch)
              : readModel.ownOrganization(query, fetch));
    }

    recordStudentsShown(groups, actor);
    return new SearchResults(query.text(), groups);
  }

  private void recordStudentsShown(List<SearchGroup> groups, CurrentActor actor) {
    Set<UUID> studentIds = new LinkedHashSet<>();
    for (SearchGroup group : groups) {
      for (SearchHit hit : group.hits()) {
        if (hit.type() == SearchResultType.STUDENT) {
          studentIds.add(hit.id());
        }
        if (hit.relatedStudentId() != null) {
          studentIds.add(hit.relatedStudentId());
        }
      }
    }
    if (studentIds.isEmpty()) {
      return;
    }

    TenantId tenantId = TenantContext.require();
    int count = studentIds.size();
    dataAccessPort.recordAll(
        studentIds.stream()
            .map(
                studentId ->
                    DataAccessRecord.listed(
                        tenantId, actor.userId(), actor.role(), studentId, count, PURPOSE))
            .toList());
  }
}
