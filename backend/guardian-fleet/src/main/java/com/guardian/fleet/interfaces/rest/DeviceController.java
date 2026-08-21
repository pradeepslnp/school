package com.guardian.fleet.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.fleet.application.command.RegisterDeviceCommand;
import com.guardian.fleet.application.usecase.AssignDeviceToVehicleUseCase;
import com.guardian.fleet.application.usecase.ListDevicesUseCase;
import com.guardian.fleet.application.usecase.RegisterDeviceUseCase;
import com.guardian.fleet.application.usecase.UnassignDeviceFromVehicleUseCase;
import com.guardian.fleet.domain.Device;
import com.guardian.fleet.domain.DeviceId;
import com.guardian.fleet.domain.VehicleId;
import com.guardian.fleet.interfaces.rest.dto.DeviceResponse;
import com.guardian.fleet.interfaces.rest.dto.RegisterDeviceRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Device endpoints (feature FLT-004). See guardian-docs/04-api/FLEET_STAFF_ROUTES_API.md.
 *
 * <p>Devices are explicitly registered by an operator. Nothing here — or anywhere in this module —
 * creates a device from an ingested position report (BR-FLEET-006).
 */
@RestController
@RequestMapping("/api/v1/devices")
public class DeviceController {

  private final RegisterDeviceUseCase registerDevice;
  private final ListDevicesUseCase listDevices;
  private final AssignDeviceToVehicleUseCase assignDevice;
  private final UnassignDeviceFromVehicleUseCase unassignDevice;

  public DeviceController(
      RegisterDeviceUseCase registerDevice,
      ListDevicesUseCase listDevices,
      AssignDeviceToVehicleUseCase assignDevice,
      UnassignDeviceFromVehicleUseCase unassignDevice) {
    this.registerDevice = registerDevice;
    this.listDevices = listDevices;
    this.assignDevice = assignDevice;
    this.unassignDevice = unassignDevice;
  }

  @PostMapping
  @RequiresPermission("PERM-DEVICE-MANAGE")
  public ResponseEntity<DeviceResponse> register(
      @Valid @RequestBody RegisterDeviceRequest request, CurrentActor actor) {

    RegisterDeviceCommand command =
        new RegisterDeviceCommand(
            request.deviceIdentifier(),
            request.vendorCode(),
            request.credentialSecret(),
            actor.userId(),
            actor.role());

    Device created = registerDevice.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/devices/" + created.id()))
        .body(DeviceResponse.from(created));
  }

  @GetMapping
  @RequiresPermission("PERM-DEVICE-MANAGE")
  public List<DeviceResponse> list() {
    return listDevices.all().stream().map(DeviceResponse::from).toList();
  }

  /** BR-FLEET-004 🔴 — refused with {@code 409 DEVICE_ALREADY_ASSIGNED} if the vehicle is taken. */
  @PutMapping("/{deviceId}/vehicle")
  @RequiresPermission("PERM-DEVICE-MANAGE")
  public DeviceResponse assign(
      @PathVariable UUID deviceId, @RequestBody Map<String, UUID> body, CurrentActor actor) {
    VehicleId vehicleId = VehicleId.of(body.get("vehicleId"));
    return DeviceResponse.from(
        assignDevice.execute(DeviceId.of(deviceId), vehicleId, actor.userId(), actor.role()));
  }

  @DeleteMapping("/{deviceId}/vehicle")
  @RequiresPermission("PERM-DEVICE-MANAGE")
  public DeviceResponse unassign(@PathVariable UUID deviceId, CurrentActor actor) {
    return DeviceResponse.from(
        unassignDevice.execute(DeviceId.of(deviceId), actor.userId(), actor.role()));
  }
}
