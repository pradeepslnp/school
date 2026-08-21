package com.guardian.staff.application.usecase;

import com.guardian.common.error.ErrorCode;
import com.guardian.common.error.ResourceNotFoundException;
import com.guardian.staff.application.port.TransportStaffRepository;
import com.guardian.staff.domain.SchoolId;
import com.guardian.staff.domain.StaffId;
import com.guardian.staff.domain.TransportStaff;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Reads transport staff (feature STF-001).
 *
 * <p>No explicit tenant filtering appears here: row-level security applies it to every query
 * (ADR-0001). A staff record in another organization is genuinely not found, which is why this
 * throws {@link ResourceNotFoundException} rather than a permission error.
 */
@Service
public class GetTransportStaffUseCase {

  private final TransportStaffRepository staffRepository;

  public GetTransportStaffUseCase(TransportStaffRepository staffRepository) {
    this.staffRepository = staffRepository;
  }

  @Transactional(readOnly = true)
  public TransportStaff byId(StaffId staffId) {
    return staffRepository
        .findById(staffId)
        .orElseThrow(
            () ->
                new ResourceNotFoundException(
                    ErrorCode.STAFF_NOT_FOUND, "TransportStaff", staffId.value()));
  }

  @Transactional(readOnly = true)
  public List<TransportStaff> bySchool(SchoolId schoolId) {
    return staffRepository.findBySchool(schoolId);
  }
}
