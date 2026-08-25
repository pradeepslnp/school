package com.guardian.identity.infrastructure.persistence;

import com.guardian.common.tenant.TenantContext;
import com.guardian.identity.application.port.UserRepository;
import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import com.guardian.identity.domain.UserStatus;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements {@link UserRepository} over JPA. */
@Component
class UserRepositoryAdapter implements UserRepository {

  private final UserJpaRepository jpaRepository;

  UserRepositoryAdapter(UserJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  public Optional<User> findById(UserId id) {
    return jpaRepository.findById(id.value()).map(UserRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<User> findByPhone(PhoneNumber phone) {
    return jpaRepository.findByPhone(phone.value()).map(UserRepositoryAdapter::toDomain);
  }

  @Override
  public Optional<User> findByEmail(String email) {
    return jpaRepository.findByEmailIgnoreCase(email).map(UserRepositoryAdapter::toDomain);
  }

  @Override
  public List<User> findAdministrativeUsers() {
    return jpaRepository.findAdministrativeUsers().stream()
        .map(UserRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  public List<String> roleCodesOf(UserId id) {
    return jpaRepository.findRoleCodes(id.value());
  }

  @Override
  public User create(User user) {
    UserEntity entity =
        new UserEntity(
            user.id().value(),
            TenantContext.require().value(),
            user.email(),
            user.phone() == null ? null : user.phone().value(),
            user.firstName(),
            user.lastName(),
            user.preferredLocale(),
            user.status().name());
    // saveAndFlush, not save: ProvisionStaffAccountUseCase grants a role for this user in the
    // same transaction immediately afterwards, via plain JDBC (JdbcRoleProvisioningRepository),
    // which bypasses Hibernate's session entirely. A batched, unflushed persist() would let that
    // INSERT INTO user_roles run before this row physically exists, tripping
    // user_roles_user_id_fkey even though both statements are in the same transaction.
    return toDomain(jpaRepository.saveAndFlush(entity));
  }

  @Override
  public User save(User user) {
    // Loads the managed instance and mutates it, rather than persisting a detached copy: only
    // then do Hibernate's dirty checking and @Version apply. A detached save would bypass
    // optimistic locking and let a concurrent administrative edit be silently overwritten by a
    // sign-in, or the reverse.
    UserEntity entity =
        jpaRepository
            .findById(user.id().value())
            .orElseThrow(
                () ->
                    new IllegalStateException(
                        "user " + user.id() + " disappeared between read and write"));

    // Applies every mutable field the domain object carries, not just lastLoginAt: this method
    // now backs both StaffLoginUseCase/VerifyOtpUseCase's post-sign-in save (which only ever
    // changes lastLoginAt, so re-applying the rest is a no-op) and
    // UpdateAdministrativeUserUseCase/SetAdministrativeUserStatusUseCase's edits (which need
    // exactly this). One save path rather than two keeps optimistic locking in one place.
    entity.applySignIn(user.lastLoginAt());
    entity.applyAdministrativeState(
        user.firstName(), user.lastName(), user.preferredLocale(), user.status().name());
    return toDomain(jpaRepository.save(entity));
  }

  private static User toDomain(UserEntity entity) {
    return User.rehydrate(
        UserId.of(entity.getId()),
        entity.getPhone() == null ? null : new PhoneNumber(entity.getPhone()),
        entity.getEmail(),
        entity.getFirstName(),
        entity.getLastName(),
        entity.getPreferredLocale(),
        UserStatus.fromStored(entity.getStatus()),
        entity.getLastLoginAt(),
        entity.getVersion());
  }
}
