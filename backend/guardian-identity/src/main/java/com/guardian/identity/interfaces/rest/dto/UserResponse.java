package com.guardian.identity.interfaces.rest.dto;

import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserScope;
import java.util.List;
import java.util.UUID;

/** Wire representation of an administrative user (screen A-43). */
public record UserResponse(
    UUID id,
    String email,
    String phone,
    String firstName,
    String lastName,
    String preferredLocale,
    String status,
    List<String> roleCodes,
    String scopeLevel,
    UUID scopeRefId) {

  public static UserResponse from(AdministrativeUserView view) {
    User user = view.user();
    // A user may in principle hold more than one scope row; today's create flow ever writes
    // exactly one, so the first is the whole answer. Revisit if a second grant path lands.
    UserScope scope = view.scopes().isEmpty() ? null : view.scopes().get(0);

    return new UserResponse(
        user.id().value(),
        user.email(),
        user.phone() == null ? null : user.phone().value(),
        user.firstName(),
        user.lastName(),
        // Included so the edit form (A-43) has a value to pre-fill and re-send:
        // UpdateUserRequest.preferredLocale is @NotBlank, and there is no other endpoint
        // that hands this back to the console once the account exists.
        user.preferredLocale(),
        user.status().name(),
        view.roleCodes(),
        scope == null ? null : scope.level().name(),
        scope == null ? null : scope.refId());
  }
}
