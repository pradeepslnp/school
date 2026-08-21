package com.guardian.staff.application.port;

import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link TransportStaff}, defined in the domain's language.
 *
 * <p>Every method here is implicitly tenant-scoped: row-level security applies the {@code
 * tenant_id} predicate to every query (ADR-0001). No method takes a tenant argument — a caller
 * cannot ask for another tenant's staff, and a forgotten filter returns zero rows rather than
 * another organization's roster.
 */
public interface TransportStaffRepository {

  Optional<TransportStaff> findById(StaffId id);

  List<TransportStaff> findBySchool(SchoolId schoolId);

  /**
   * Whether another record at this school already holds {@code employeeCode} — a pre-flight check
   * against {@code uq_staff_school_employee_code}, a data-integrity constraint rather than a
   * documented business rule (see {@code CreateTransportStaffUseCase}'s own note on that
   * distinction). {@code excludingStaffId} is the record being edited, if any, so that saving a
   * staff member without having changed their own code does not conflict with itself; pass null
   * when checking a brand-new record instead.
   */
  boolean existsByEmployeeCode(SchoolId schoolId, String employeeCode, StaffId excludingStaffId);

  TransportStaff save(TransportStaff staff);
}
