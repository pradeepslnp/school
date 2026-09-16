package com.guardian.search.application.port;

import com.guardian.common.security.AccessScope;
import com.guardian.search.domain.SearchHit;
import com.guardian.search.domain.SearchQuery;
import java.util.List;

/**
 * Global search's cross-module read (ADR-0017) — one port, one adapter, one file of SQL, the same
 * bounded exception to "a module owns its tables" that ADR-0010 accepts for MOD-18.
 *
 * <p><strong>Scope is the implementation's job, not the caller's.</strong> Every school-bound
 * method applies {@code scope} inside the query, so a record outside it is never read, never held
 * in memory, and never logged as seen (BR-IAM-006). A method that returned everything and left
 * filtering to the use case would put the school boundary one forgotten {@code filter} away.
 *
 * <p>Each method returns at most {@code limit} rows; callers ask for one more than they show to
 * learn whether there are more. Read-only by construction: there is no write method here.
 */
public interface SearchReadModel {

  /** Students by name or admission number, within {@code scope}. */
  List<SearchHit> students(SearchQuery query, AccessScope scope, int limit);

  /**
   * Guardians by name, phone, or email — only those actively linked to a student within {@code
   * scope}, each carrying that student as its related child.
   */
  List<SearchHit> guardians(SearchQuery query, AccessScope scope, int limit);

  /** Drivers and attendants by name, phone, or employee code, within {@code scope}. */
  List<SearchHit> staff(SearchQuery query, AccessScope scope, int limit);

  /** Vehicles by display name or registration number, within {@code scope}. */
  List<SearchHit> vehicles(SearchQuery query, AccessScope scope, int limit);

  /** Routes by name or code, within {@code scope}. */
  List<SearchHit> routes(SearchQuery query, AccessScope scope, int limit);

  /** Schools by name or code, within {@code scope}. */
  List<SearchHit> schools(SearchQuery query, AccessScope scope, int limit);

  /**
   * Administrative accounts — the Users screen's set — by name, email, or phone. An
   * organization-wide scope sees all of them; a school scope sees only accounts scoped to its
   * schools.
   */
  List<SearchHit> administrativeUsers(SearchQuery query, AccessScope scope, int limit);

  /** The organization the request acts in, if its name or code matches — row-level security. */
  List<SearchHit> ownOrganization(SearchQuery query, int limit);
}
