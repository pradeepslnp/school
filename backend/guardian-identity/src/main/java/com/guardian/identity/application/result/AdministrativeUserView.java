package com.guardian.identity.application.result;

import com.guardian.identity.domain.User;
import com.guardian.identity.domain.UserScope;
import java.util.List;

/**
 * A {@link User} together with the role and scope information the Users screen (A-43) needs to
 * display, that {@code User} itself does not carry (roles and scopes are resolved separately — see
 * {@code UserRepository.roleCodesOf} and {@code UserScopeRepository}).
 */
public record AdministrativeUserView(User user, List<String> roleCodes, List<UserScope> scopes) {}
