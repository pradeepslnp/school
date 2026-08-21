plugins {
    java
    alias(libs.plugins.spring.boot) apply false
    alias(libs.plugins.spring.dependency.management)
    alias(libs.plugins.spotless)
}

allprojects {
    group = "com.guardian"
    version = "0.1.0-SNAPSHOT"

    repositories {
        mavenCentral()
    }
}

subprojects {
    apply(plugin = "java")
    apply(plugin = "io.spring.dependency-management")
    apply(plugin = "com.diffplug.spotless")

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(21))
        }
    }

    the<io.spring.gradle.dependencymanagement.dsl.DependencyManagementExtension>().apply {
        imports {
            mavenBom(
                org.springframework.boot.gradle.plugin.SpringBootPlugin.BOM_COORDINATES,
            )
        }
    }

    dependencies {
        "testImplementation"(rootProject.libs.spring.boot.starter.test)
        "testImplementation"(rootProject.libs.archunit.junit5)

        // Gradle 9 no longer puts the JUnit Platform launcher on the test runtime
        // classpath implicitly; without it every test task fails to start.
        "testRuntimeOnly"("org.junit.platform:junit-platform-launcher")
    }

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(listOf("-Xlint:all", "-parameters"))
    }

    tasks.withType<Test>().configureEach {
        useJUnitPlatform()
        testLogging {
            events("passed", "skipped", "failed")
        }
    }

    // Integration tests (*IT) are separated from unit tests: they need Docker and
    // are far slower, so `./gradlew test` stays fast enough to run constantly.
    // See docs/07-testing/TEST_STRATEGY.md.
    tasks.named<Test>("test") {
        filter { excludeTestsMatching("*IT") }
    }

    tasks.register<Test>("integrationTest") {
        description = "Runs integration tests (*IT) against Testcontainers PostgreSQL."
        group = "verification"
        testClassesDirs = sourceSets["test"].output.classesDirs
        classpath = sourceSets["test"].runtimeClasspath
        filter {
            includeTestsMatching("*IT")
            // Modules with no integration tests yet are not a build failure. Gradle's default
            // treats an empty match as an error, which would force every new module to carry a
            // placeholder IT before it could build.
            isFailOnNoMatchingTests = false
        }
        shouldRunAfter(tasks.named("test"))

        // Docker Desktop on macOS listens on a per-user socket. Testcontainers finds it via
        // DOCKER_HOST, which the Gradle daemon only carries if it was started after Docker —
        // otherwise every *IT fails with "Could not find a valid Docker environment", which
        // reads like a broken test rather than a stale daemon. Resolving it here makes the
        // task independent of daemon start order.
        val dockerHost =
            providers.environmentVariable("DOCKER_HOST").orElse(
                providers.provider {
                    val userSocket = File(System.getProperty("user.home"), ".docker/run/docker.sock")
                    if (userSocket.exists()) "unix://${userSocket.absolutePath}" else ""
                },
            )
        if (dockerHost.get().isNotEmpty()) {
            environment("DOCKER_HOST", dockerHost.get())
        }

        // Docker Engine 29 removed API versions below 1.40, but the docker-java client bundled
        // with Testcontainers still negotiates down to 1.32 and gets a bare HTTP 400. Testcontainers
        // reports that as "Could not find a valid Docker environment", which points at the socket
        // rather than at version negotiation and is a genuinely hard failure to diagnose.
        //
        // 1.40 is the engine's stated minimum, so it is the safe floor across engine versions.
        val dockerApiVersion =
            providers.environmentVariable("DOCKER_API_VERSION").getOrElse("1.40")
        environment("DOCKER_API_VERSION", dockerApiVersion)
        // docker-java reads this system property directly; the environment variable alone is
        // not enough on every code path.
        systemProperty("api.version", dockerApiVersion)
    }

    spotless {
        java {
            // Pinned rather than left to Spotless's default. google-java-format reaches into
            // javac internals, which JDK 26 changed — an unpinned default silently picks a
            // build-breaking version depending on the Spotless release.
            googleJavaFormat("1.27.0")
            removeUnusedImports()
            trimTrailingWhitespace()
            endWithNewline()
        }
    }
}
