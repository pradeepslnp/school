package com.guardian.fleet.application.usecase;

import com.guardian.fleet.application.port.DeviceRepository;
import com.guardian.fleet.domain.Device;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ListDevicesUseCase {

  private final DeviceRepository deviceRepository;

  public ListDevicesUseCase(DeviceRepository deviceRepository) {
    this.deviceRepository = deviceRepository;
  }

  @Transactional(readOnly = true)
  public List<Device> all() {
    return deviceRepository.findByTenant();
  }
}
