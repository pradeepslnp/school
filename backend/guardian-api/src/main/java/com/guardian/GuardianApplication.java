package com.guardian;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Application bootstrap.
 *
 * <p>The same modules are deployed in three roles — API, ingestion, and worker — selected by
 * profile. They are separated because their load profiles differ sharply, not because their code
 * does (guardian-docs/02-system-design/ARCHITECTURE_OVERVIEW.md).
 */
@SpringBootApplication
@EnableTransactionManagement
public class GuardianApplication {

  public static void main(String[] args) {
    SpringApplication.run(GuardianApplication.class, args);
  }
}
