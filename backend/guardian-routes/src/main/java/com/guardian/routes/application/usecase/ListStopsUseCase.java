package com.guardian.routes.application.usecase;

import com.guardian.routes.application.port.StopRepository;
import com.guardian.routes.domain.RouteId;
import com.guardian.routes.domain.Stop;
import java.util.List;
import org.springframework.stereotype.Service;

/** Lists a route's stops, in sequence (feature RTE-001). */
@Service
public class ListStopsUseCase {

  private final StopRepository stopRepository;

  public ListStopsUseCase(StopRepository stopRepository) {
    this.stopRepository = stopRepository;
  }

  public List<Stop> forRoute(RouteId routeId) {
    return stopRepository.findByRoute(routeId);
  }
}
