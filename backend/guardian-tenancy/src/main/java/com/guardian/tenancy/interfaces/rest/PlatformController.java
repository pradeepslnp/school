package com.guardian.tenancy.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.tenancy.application.usecase.GetPlatformHealthUseCase;
import com.guardian.tenancy.interfaces.rest.dto.PlatformHealthResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Platform Operations endpoints (screen A-62). See {@link GetPlatformHealthUseCase}'s Javadoc for
 * why this lives in {@code guardian-tenancy} rather than a dedicated platform module, and for what
 * "health" does and does not mean here.
 *
 * <p>Translation only, matching every other controller in this module: parse nothing (this
 * endpoint takes no input beyond the caller's own identity), call one use case, map the result.
 */
@RestController
@RequestMapping("/api/v1/platform")
public class PlatformController {

  private final GetPlatformHealthUseCase getPlatformHealth;

  public PlatformController(GetPlatformHealthUseCase getPlatformHealth) {
    this.getPlatformHealth = getPlatformHealth;
  }

  @GetMapping("/health")
  @RequiresPermission("PERM-PLATFORM-HEALTH-VIEW")
  public PlatformHealthResponse health(CurrentActor actor) {
    return PlatformHealthResponse.from(getPlatformHealth.execute(actor.role()));
  }
}
