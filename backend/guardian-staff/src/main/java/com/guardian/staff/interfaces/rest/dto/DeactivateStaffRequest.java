package com.guardian.staff.interfaces.rest.dto;

/** Wire format for {@code POST /transport-staff/{id}/deactivate} (feature IAM-008). */
public record DeactivateStaffRequest(String reason) {}
