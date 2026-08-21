package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.tenancy.application.port.OrganizationCodeDirectory;
import com.guardian.tenancy.domain.OrganizationCode;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calls {@code org_code_exists} from V11__organization_code_resolution.sql.
 *
 * <p>Plain JDBC, not JPA — this is a function call returning one boolean, not an entity read, and
 * routing it through Hibernate would put {@code OrganizationEntity} in a persistence context that
 * has no tenant. {@link Propagation#NOT_SUPPORTED} for the same reason {@code
 * JdbcPreAuthenticationDirectory} uses it: this runs before the new organization's tenant context
 * exists, and joining a transaction already carrying a different {@code SET LOCAL} would run the
 * function under it. Suspended, this gets its own connection with no tenant set — correct, since
 * the function runs as its owner.
 */
@Component
class JdbcOrganizationCodeDirectory implements OrganizationCodeDirectory {

  private final JdbcTemplate jdbcTemplate;

  JdbcOrganizationCodeDirectory(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public boolean existsGlobally(OrganizationCode code) {
    Boolean exists =
        jdbcTemplate.queryForObject("SELECT org_code_exists(?)", Boolean.class, code.value());
    return Boolean.TRUE.equals(exists);
  }
}
