package com.guardian.routes.application.usecase;

import com.guardian.routes.application.port.RouteRepository;
import com.guardian.routes.domain.Route;
import com.guardian.routes.domain.SchoolId;
import java.util.List;
import org.springframework.stereotype.Service;

/** Lists a school's routes (feature RTE-001). */
@Service
public class ListRoutesUseCase {

  private final RouteRepository routeRepository;

  public ListRoutesUseCase(RouteRepository routeRepository) {
    this.routeRepository = routeRepository;
  }

  public List<Route> bySchool(SchoolId schoolId) {
    return routeRepository.findBySchool(schoolId);
  }
}
