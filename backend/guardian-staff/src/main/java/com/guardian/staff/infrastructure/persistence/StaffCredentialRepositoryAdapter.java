package com.guardian.staff.infrastructure.persistence;

import com.guardian.staff.application.port.StaffCredentialRepository;
import com.guardian.staff.domain.StaffCredential;
import com.guardian.staff.domain.StaffCredentialId;
import com.guardian.staff.domain.StaffId;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Limit;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

@Component
class StaffCredentialRepositoryAdapter implements StaffCredentialRepository {

  private final StaffCredentialJpaRepository jpaRepository;
  private final StaffCredentialPersistenceMapper mapper;

  StaffCredentialRepositoryAdapter(
      StaffCredentialJpaRepository jpaRepository, StaffCredentialPersistenceMapper mapper) {
    this.jpaRepository = jpaRepository;
    this.mapper = mapper;
  }

  @Override
  public Optional<StaffCredential> findById(StaffCredentialId id) {
    return jpaRepository.findById(id.value()).map(mapper::toDomain);
  }

  @Override
  public List<StaffCredential> findByStaff(StaffId staffId) {
    return jpaRepository.findByStaffId(staffId.value()).stream().map(mapper::toDomain).toList();
  }

  @Override
  public List<StaffCredential> findMandatoryByStaff(StaffId staffId) {
    return jpaRepository.findByStaffIdAndMandatoryTrue(staffId.value()).stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public List<StaffCredential> findMandatoryExpiringWithin(LocalDate asOf, int days, int limit) {
    return jpaRepository
        .findMandatoryExpiringBy(asOf.plusDays(days), Sort.by("expiresOn"), Limit.of(limit))
        .stream()
        .map(mapper::toDomain)
        .toList();
  }

  @Override
  public StaffCredential save(StaffCredential credential) {
    StaffCredentialEntity entity =
        jpaRepository
            .findById(credential.id().value())
            .map(
                managed -> {
                  mapper.applyTo(managed, credential);
                  return managed;
                })
            .orElseGet(() -> mapper.toEntity(credential));

    return mapper.toDomain(jpaRepository.save(entity));
  }
}
