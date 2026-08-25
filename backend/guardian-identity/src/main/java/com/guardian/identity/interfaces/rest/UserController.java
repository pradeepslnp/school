package com.guardian.identity.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.identity.application.command.CreateAdministrativeUserCommand;
import com.guardian.identity.application.command.UpdateAdministrativeUserCommand;
import com.guardian.identity.application.result.AdministrativeUserView;
import com.guardian.identity.application.usecase.CreateAdministrativeUserUseCase;
import com.guardian.identity.application.usecase.ListAdministrativeUsersUseCase;
import com.guardian.identity.application.usecase.SetAdministrativeUserStatusUseCase;
import com.guardian.identity.application.usecase.UpdateAdministrativeUserUseCase;
import com.guardian.identity.domain.UserStatus;
import com.guardian.identity.interfaces.rest.dto.CreateUserRequest;
import com.guardian.identity.interfaces.rest.dto.UpdateUserRequest;
import com.guardian.identity.interfaces.rest.dto.UserResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Administrative user endpoints (feature IAM-005, IAM-008; screen A-43). See
 * guardian-docs/04-api/TENANCY_IDENTITY_API.md.
 *
 * <p>Every endpoint takes {@code organizationId} — as a body field on create, a query parameter
 * everywhere else — rather than resolving it server-side from the target user or school. See
 * {@link CreateAdministrativeUserUseCase}'s documentation for why: the admin console already knows
 * this id from the same cascading organization/school picker that gates Students, Drivers,
 * Vehicles, and Routes, and resolving it independently here would mean a second, redundant lookup
 * for information the caller already has.
 *
 * <p>This layer only translates: parse the wire format into domain types, call one use case, map
 * the result back — matching {@code OrganizationController}.
 */
@RestController
@RequestMapping("/api/v1/users")
public class UserController {

  private final CreateAdministrativeUserUseCase createUser;
  private final ListAdministrativeUsersUseCase listUsers;
  private final UpdateAdministrativeUserUseCase updateUser;
  private final SetAdministrativeUserStatusUseCase setUserStatus;

  public UserController(
      CreateAdministrativeUserUseCase createUser,
      ListAdministrativeUsersUseCase listUsers,
      UpdateAdministrativeUserUseCase updateUser,
      SetAdministrativeUserStatusUseCase setUserStatus) {
    this.createUser = createUser;
    this.listUsers = listUsers;
    this.updateUser = updateUser;
    this.setUserStatus = setUserStatus;
  }

  @GetMapping
  @RequiresPermission("PERM-USER-VIEW")
  public List<UserResponse> list(
      @RequestParam UUID organizationId, CurrentActor actor) {
    return listUsers.execute(organizationId, actor.role()).stream()
        .map(UserResponse::from)
        .toList();
  }

  @PostMapping
  @RequiresPermission("PERM-USER-CREATE")
  public ResponseEntity<UserResponse> create(
      @Valid @RequestBody CreateUserRequest request, CurrentActor actor) {

    CreateAdministrativeUserCommand command =
        new CreateAdministrativeUserCommand(
            request.organizationId(),
            request.schoolId(),
            request.email(),
            request.phone(),
            request.firstName(),
            request.lastName(),
            request.roleCode(),
            request.initialPassword(),
            actor.userId(),
            actor.role());

    AdministrativeUserView created = createUser.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/users/" + created.user().id().value()))
        .body(UserResponse.from(created));
  }

  @PatchMapping("/{userId}")
  @RequiresPermission("PERM-USER-EDIT")
  public UserResponse update(
      @PathVariable UUID userId,
      @Valid @RequestBody UpdateUserRequest request,
      CurrentActor actor) {

    UpdateAdministrativeUserCommand command =
        new UpdateAdministrativeUserCommand(
            request.organizationId(),
            userId,
            request.firstName(),
            request.lastName(),
            request.preferredLocale(),
            actor.userId(),
            actor.role());

    return UserResponse.from(updateUser.execute(command));
  }

  @PatchMapping("/{userId}/deactivate")
  @RequiresPermission("PERM-USER-DEACTIVATE")
  public UserResponse deactivate(
      @PathVariable UUID userId, @RequestParam UUID organizationId, CurrentActor actor) {
    return UserResponse.from(
        setUserStatus.execute(
            organizationId, userId, UserStatus.INACTIVE, actor.userId(), actor.role()));
  }

  @PatchMapping("/{userId}/reactivate")
  @RequiresPermission("PERM-USER-DEACTIVATE")
  public UserResponse reactivate(
      @PathVariable UUID userId, @RequestParam UUID organizationId, CurrentActor actor) {
    return UserResponse.from(
        setUserStatus.execute(
            organizationId, userId, UserStatus.ACTIVE, actor.userId(), actor.role()));
  }
}
