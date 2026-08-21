package com.guardian.routes.infrastructure.persistence;

import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.SchoolId;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/** Implements the domain-facing {@link RouteRepository} over JPA. */
@Component
class RouteRepositoryAdapter implements RouteRepository {

  private final RouteJpaRepository jpaRepository;
  private final RoutePersistenceMapper mapper;

  RouteRepositoryAdapter(RouteJpaRepository jpaRepository, RoutePersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<Route> findById(RouteId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<Route> findBySchool(SchoolId schoolId) {
    return jpaRepository.findBySchoolIdOrderByName(schoolId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public boolean existsByCode(SchoolId schoolId, String code) {
    return jpaRepository.existsBySchoolIdAndCode(schoolId.value(), code);
  }

  @Override
  public Route save(Route route) {
    RouteEntity entity =
        jpaRepository
            .findById(route.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, route);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(route));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
