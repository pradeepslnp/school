package com.guardian.student;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.guardian.AbstractIntegrationTest;
import com.guardian.common.BusinessRule;
import com.guardian.identity.application.port.AccessTokenIssuer;
import com.guardian.identity.domain.ClientType;
import com.guardian.identity.domain.SessionId;
import com.guardian.identity.domain.UserId;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

/**
 * The student endpoints over real HTTP, with the security chain and the database in place.
 *
 * <p>Two guarantees here are not observable at any lower level: that a non-guardian read leaves a
 * data-access record in the same transaction (BR-IAM-012 🔴), and that a duplicate admission number
 * is refused with a code the office can act on rather than a constraint violation (BR-STU-003).
 */
@AutoConfigureMockMvc
class StudentApiIT extends AbstractIntegrationTest {

  private static final UUID SCHOOL_ID = UUID.randomUUID();
  private static final UUID ADMIN_USER_ID = UUID.randomUUID();
  private static final UUID ADMIN_ROLE_ID = UUID.randomUUID();

  @Autowired private MockMvc mockMvc;
  @Autowired private AccessTokenIssuer accessTokenIssuer;

  @BeforeEach
  void seed() {
    JdbcTemplate owner = ownerJdbcTemplate();

    // data_access_records has no FK to organizations, so the base class's TRUNCATE ... CASCADE
    // does not reach it and rows would outlive the test that wrote them.
    owner.execute("TRUNCATE TABLE data_access_records");

    owner.update(
        """
        INSERT INTO schools (id, tenant_id, organization_id, code, name, timezone,
                             latitude, longitude, geofence_radius_m, status)
        VALUES (?, ?, ?, 'SCH-A', 'Greenwood High', 'Asia/Kolkata',
                12.971600, 77.594600, 150, 'ACTIVE')
        """,
        SCHOOL_ID,
        ORGANIZATION_A,
        ORGANIZATION_A);

    owner.update(
        """
        INSERT INTO roles (id, tenant_id, code, name, is_system_role)
        VALUES (?, ?, 'SCHOOL_ADMIN', 'School Administrator', true)
        """,
        ADMIN_ROLE_ID,
        ORGANIZATION_A);

    owner.update(
        """
        INSERT INTO users (id, tenant_id, email, first_name, last_name, preferred_locale, status)
        VALUES (?, ?, 'fatima@greenwood.test', 'Fatima', 'Khan', 'en', 'ACTIVE')
        """,
        ADMIN_USER_ID,
        ORGANIZATION_A);

    owner.update(
        "INSERT INTO user_roles (id, tenant_id, user_id, role_id) VALUES (?, ?, ?, ?)",
        UUID.randomUUID(),
        ORGANIZATION_A,
        ADMIN_USER_ID,
        ADMIN_ROLE_ID);
  }

  @Test
  @BusinessRule({"BR-STU-001", "BR-STU-003"})
  @DisplayName("a student is enrolled, and a second student cannot reuse their admission number")
  void enrolsAndRefusesDuplicateAdmissionNumber() throws Exception {
    mockMvc
        .perform(
            post("/api/v1/students")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody("GW-2024-0117", "Aarav", "Sharma")))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.admissionNo").value("GW-2024-0117"))
        .andExpect(jsonPath("$.data.enrolmentStatus").value("ACTIVE"))
        // photoRef is a storage key and must never reach a client.
        .andExpect(jsonPath("$.data.photoRef").doesNotExist());

    mockMvc
        .perform(
            post("/api/v1/students")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(createBody("gw-2024-0117", "Different", "Child")))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("STUDENT_ADMISSION_NO_EXISTS"))
        .andExpect(jsonPath("$.error.businessRule").value("BR-STU-003"));
  }

  @Test
  @BusinessRule("BR-IAM-012")
  @DisplayName("a non-guardian read of a student's record is recorded")
  void nonGuardianReadWritesDataAccessRecord() throws Exception {
    String location =
        mockMvc
            .perform(
                post("/api/v1/students")
                    .header("Authorization", "Bearer " + adminToken())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(createBody("GW-1", "Aarav", "Sharma")))
            .andExpect(status().isCreated())
            .andReturn()
            .getResponse()
            .getHeader("Location");

    assertThat(location).isNotNull();
    String studentId = location.substring(location.lastIndexOf('/') + 1);

    mockMvc
        .perform(
            get("/api/v1/students/" + studentId).header("Authorization", "Bearer " + adminToken()))
        .andExpect(status().isOk());

    JdbcTemplate owner = ownerJdbcTemplate();
    Integer views =
        owner.queryForObject(
            """
            SELECT count(*) FROM data_access_records
            WHERE student_id = ?::uuid AND actor_id = ? AND access_type = 'VIEW'
            """,
            Integer.class,
            studentId,
            ADMIN_USER_ID);

    assertThat(views).as("a school admin opening a child's record must leave a trace").isEqualTo(1);
  }

  @Test
  @BusinessRule("BR-IAM-012")
  @DisplayName("listing the register records one access per student listed")
  void listingWritesOneRecordPerStudent() throws Exception {
    for (int i = 1; i <= 3; i++) {
      mockMvc
          .perform(
              post("/api/v1/students")
                  .header("Authorization", "Bearer " + adminToken())
                  .contentType(MediaType.APPLICATION_JSON)
                  .content(createBody("L-" + i, "Child", "Number" + i)))
          .andExpect(status().isCreated());
    }

    mockMvc
        .perform(
            get("/api/v1/students")
                .param("schoolId", SCHOOL_ID.toString())
                .header("Authorization", "Bearer " + adminToken()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.length()").value(3))
        .andExpect(jsonPath("$.meta.pagination.hasMore").value(false))
        .andExpect(jsonPath("$.meta.pagination.limit").value(50));

    JdbcTemplate owner = ownerJdbcTemplate();
    Integer listed =
        owner.queryForObject(
            "SELECT count(*) FROM data_access_records WHERE access_type = 'LIST'", Integer.class);

    // One row per child, not one per page: "who read Aarav's data?" must be answerable, and a
    // single summary row would leave it unanswered.
    assertThat(listed).isEqualTo(3);
  }

  @Test
  @DisplayName("the register pages with a cursor rather than an offset")
  void registerPagesWithACursor() throws Exception {
    for (int i = 1; i <= 3; i++) {
      mockMvc
          .perform(
              post("/api/v1/students")
                  .header("Authorization", "Bearer " + adminToken())
                  .contentType(MediaType.APPLICATION_JSON)
                  .content(createBody("P-" + i, "Child", "Number" + i)))
          .andExpect(status().isCreated());
    }

    String cursor =
        mockMvc
            .perform(
                get("/api/v1/students")
                    .param("schoolId", SCHOOL_ID.toString())
                    .param("limit", "2")
                    .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.length()").value(2))
            .andExpect(jsonPath("$.meta.pagination.hasMore").value(true))
            .andExpect(jsonPath("$.meta.pagination.nextCursor").value("P-2"))
            .andReturn()
            .getResponse()
            .getContentAsString();

    assertThat(cursor).contains("P-1").contains("P-2").doesNotContain("P-3");

    mockMvc
        .perform(
            get("/api/v1/students")
                .param("schoolId", SCHOOL_ID.toString())
                .param("cursor", "P-2")
                .param("limit", "2")
                .header("Authorization", "Bearer " + adminToken()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.length()").value(1))
        .andExpect(jsonPath("$.data[0].admissionNo").value("P-3"))
        .andExpect(jsonPath("$.meta.pagination.hasMore").value(false));
  }

  @Test
  @BusinessRule("BR-STU-005")
  @DisplayName("withdrawal changes status and keeps the record")
  void withdrawalKeepsTheRecord() throws Exception {
    String location =
        mockMvc
            .perform(
                post("/api/v1/students")
                    .header("Authorization", "Bearer " + adminToken())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(createBody("W-1", "Aarav", "Sharma")))
            .andReturn()
            .getResponse()
            .getHeader("Location");

    String studentId = location.substring(location.lastIndexOf('/') + 1);

    mockMvc
        .perform(
            post("/api/v1/students/" + studentId + "/withdraw")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"family relocated\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.enrolmentStatus").value("WITHDRAWN"))
        .andExpect(jsonPath("$.data.transportEligible").value(false));

    // Still readable — the record outlives the enrolment because safety records reference it.
    mockMvc
        .perform(
            get("/api/v1/students/" + studentId).header("Authorization", "Bearer " + adminToken()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.admissionNo").value("W-1"));
  }

  private String createBody(String admissionNo, String firstName, String lastName) {
    return """
        {
          "schoolId": "%s",
          "admissionNo": "%s",
          "firstName": "%s",
          "lastName": "%s",
          "dateOfBirth": "2015-04-12"
        }
        """
        .formatted(SCHOOL_ID, admissionNo, firstName, lastName);
  }

  private String adminToken() {
    return accessTokenIssuer
        .issue(
            new AccessTokenIssuer.Claims(
                UserId.of(ADMIN_USER_ID),
                TENANT_A,
                SessionId.of(UUID.randomUUID()),
                ClientType.ADMIN_WEB))
        .value();
  }
}
