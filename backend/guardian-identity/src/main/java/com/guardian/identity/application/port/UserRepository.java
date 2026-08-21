package com.guardian.identity.application.port;

import com.guardian.identity.domain.PhoneNumber;
import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserId;
import java.util.List;
import java.util.Optional;

/**
 * Persistence for {@link User}.
 *
 * <p>Every method is implicitly tenant-scoped: row-level security applies the {@code tenant_id}
 * predicate to every statement (ADR-0001).
 */
public interface UserRepository {

  Optional<User> findById(UserId id);

  /**
   * A phone lookup <em>within</em> the caller's own tenant — different from {@link
   * PreAuthenticationDirectory#findByPhone}, which runs before any tenant is known and searches
   * every tenant for that reason. This one only makes sense from inside an already-established
   * tenant context (feature STF-001: checking whether a driver's number already has an account in
   * this tenant before minting a second one).
   */
  Optional<User> findByPhone(PhoneNumber phone);

  /**
   * The user's role codes, read at the moment of asking.
   *
   * <p>Not cached on the user and not carried in the access token: a permission or role change must
   * take effect on the next request, not at the next token issue (BR-IAM-004). That is the whole
   * reason the token carries no roles.
   */
  List<String> roleCodesOf(UserId id);

  User save(User user);

  /**
   * Inserts a brand-new user (feature STF-001/MOD-02). Distinct from {@link #save}, which only ever
   * updates a row it first re-reads — see that method's documentation. There is no existing row to
   * re-read here, which is exactly what makes this a different operation, not an overload.
   */
  User create(User user);
}
