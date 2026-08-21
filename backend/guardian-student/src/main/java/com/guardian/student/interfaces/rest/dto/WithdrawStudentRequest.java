package com.guardian.student.interfaces.rest.dto;

import jakarta.validation.constraints.Size;

/**
 * Wire format for taking a student off the roll.
 *
 * <p>{@code reason} is optional here, unlike an override (BR-AUD-004). A withdrawal is an ordinary
 * administrative act with an obvious cause — the child left — and demanding a justification for
 * every one trains staff to type "left" until the field means nothing.
 */
public record WithdrawStudentRequest(@Size(max = 500) String reason) {}
