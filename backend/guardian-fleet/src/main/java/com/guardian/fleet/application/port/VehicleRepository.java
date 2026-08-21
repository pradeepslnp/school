package com.guardian.fleet.application.port;

import com.guardian.fleet.domain.RegistrationNo;
import com.guardian.fleet.domain.SchoolId;
import com.guardian.fleet.domain.Vehicle;
import com.guardian.fleet.domain.VehicleId;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link Vehicle}, defined in the domain's language.
 *
 * <p>Every method here is implicitly tenant-scoped: row-level security applies the {@code
 * tenant_id} predicate to every query (ADR-0001). No method takes a tenant argument — a caller
 * cannot ask for another tenant's vehicles, and a forgotten filter returns zero rows rather than
 * another organization's fleet.
 */
public interface VehicleRepository {

  Optional<Vehicle> findById(VehicleId id);

  List<Vehicle> findBySchool(SchoolId schoolId);

  boolean existsByRegistrationNo(RegistrationNo registrationNo);

  Vehicle save(Vehicle vehicle);
}
