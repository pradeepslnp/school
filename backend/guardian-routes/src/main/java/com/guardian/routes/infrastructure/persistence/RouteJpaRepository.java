package com.guardian.routes.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface RouteJpaRepository extends JpaRepository<RouteEntity, UUID> {

  List<RouteEntity> findBySchoolIdOrderByName(UUID schoolId);

  boolean existsBySchoolIdAndCode(UUID schoolId, String code);
}
