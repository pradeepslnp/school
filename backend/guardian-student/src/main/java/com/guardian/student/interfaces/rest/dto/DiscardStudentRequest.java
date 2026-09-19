package com.guardian.student.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Wire format for {@code POST /students/{id}/discard} (feature STU-008, BR-STU-007).
 *
 * <p>{@code reason} is required, unlike a withdrawal's: this removes a child's record permanently,
 * and the audit trail is all that will say why (ADR-0019).
 */
public record DiscardStudentRequest(@NotBlank @Size(max = 500) String reason) {}
