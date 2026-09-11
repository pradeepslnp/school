dependencies {
    implementation(project(":guardian-common"))
    implementation(rootProject.libs.spring.boot.starter)
    implementation(rootProject.libs.spring.boot.starter.data.jpa)
    implementation(rootProject.libs.spring.boot.starter.web)
    implementation(rootProject.libs.spring.boot.starter.validation)

    // Real account-lifecycle email delivery over SMTP (ADR-0014). The logging adapter stays the
    // default; this only supplies JavaMailSender for SmtpAccountEmailSender.
    implementation(rootProject.libs.spring.boot.starter.mail)

    // Authentication (MOD-02, ADR-0006). Individual libraries rather than the Spring Security
    // starter — see libs.versions.toml for why.
    implementation(rootProject.libs.spring.security.crypto)
    runtimeOnly(rootProject.libs.bouncycastle.provider)
    implementation(rootProject.libs.nimbus.jose.jwt)
}
