package com.guardian.student.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Spring Data repository for {@code students}. Package-private — callers use {@link
 * com.guardian.student.application.port.StudentRepository}.
 *
 * <p>Nothing here filters on {@code tenant_id}: row-level security applies that predicate to every
 * statement (ADR-0001).
 */
interface StudentJpaRepository extends JpaRepository<StudentEntity, UUID> {

  boolean existsBySchoolIdAndAdmissionNo(UUID schoolId, String admissionNo);

  /**
   * The first page of a school's register.
   *
   * <p>Ordered by {@code admission_no}, which {@code uq_students_admission (tenant_id, school_id,
   * admission_no)} already indexes — so paging walks the index rather than sorting the school's
   * whole roll on every request.
   */
  @Query(
      """
      SELECT s FROM StudentEntity s
      WHERE s.schoolId = :schoolId
      ORDER BY s.admissionNo ASC
      """)
  List<StudentEntity> findFirstPage(@Param("schoolId") UUID schoolId, Limit limit);

  /**
   * The page following {@code afterAdmissionNo}.
   *
   * <p>A keyset predicate, not an offset. {@code OFFSET} would re-scan every skipped row and, when
   * a student is enrolled while an operator pages, shift the window so a child is shown twice or
   * not at all — on a register, the second of those is somebody missing from a list being checked.
   */
  @Query(
      """
      SELECT s FROM StudentEntity s
      WHERE s.schoolId = :schoolId
        AND s.admissionNo > :afterAdmissionNo
      ORDER BY s.admissionNo ASC
      """)
  List<StudentEntity> findPageAfter(
      @Param("schoolId") UUID schoolId,
      @Param("afterAdmissionNo") String afterAdmissionNo,
      Limit limit);
}
