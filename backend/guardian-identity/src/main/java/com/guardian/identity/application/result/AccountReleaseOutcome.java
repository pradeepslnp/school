package com.guardian.identity.application.result;

/**
 * What releasing a role from a sign-in account did (BR-IAM-014, ADR-0019). Recorded on the audit
 * trail of whatever triggered the release, so a reviewer can tell a shared account that merely lost
 * one role from one that was switched off.
 */
public enum AccountReleaseOutcome {
  /** The role was removed and its sessions revoked; the account still holds another role. */
  ROLE_REMOVED,
  /** The role was removed, its sessions revoked, and with no role left the account is inactive. */
  ACCOUNT_DEACTIVATED,
  /** No account exists under that id in this tenant — nothing to release. */
  ACCOUNT_NOT_FOUND
}
