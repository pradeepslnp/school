package com.guardian.tenancy.infrastructure.persistence;

import com.guardian.tenancy.application.port.PlatformOrganizationDirectory;
import com.guardian.tenancy.domain.Organization;
import com.guardian.tenancy.domain.OrganizationCode;
import com.guardian.tenancy.domain.OrganizationId;
import com.guardian.tenancy.domain.OrganizationStatus;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Calls {@code list_organizations()} from V12__organization_listing.sql.
 *
 * <p>Plain JDBC, not JPA — same reasoning as {@link JdbcOrganizationCodeDirectory}: this reads rows
 * through a function that runs as its {@code BYPASSRLS} owner, not as an ordinary tenant-scoped
 * entity fetch, so routing it through Hibernate's persistence context would be misleading. {@link
 * Propagation#NOT_SUPPORTED} for the same reason — this must not join a transaction that already
 * has a different {@code SET LOCAL app.tenant_id} in effect.
 */
@Component
class JdbcPlatformOrganizationDirectory implements PlatformOrganizationDirectory {

  private final JdbcTemplate jdbcTemplate;

  JdbcPlatformOrganizationDirectory(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  public List<Organization> listAll() {
    return jdbcTemplate.query("SELECT * FROM list_organizations()", this::toOrganization);
  }

  private Organization toOrganization(java.sql.ResultSet rs, int rowNum)
      throws java.sql.SQLException {
    return new Organization(
        OrganizationId.of(rs.getObject("id", UUID.class)),
        OrganizationCode.of(rs.getString("code")),
        rs.getString("name"),
        rs.getString("region_profile_code"),
        OrganizationStatus.valueOf(rs.getString("status")),
        rs.getString("contact_email"),
        rs.getString("contact_phone"),
        rs.getLong("version"));
  }
}
