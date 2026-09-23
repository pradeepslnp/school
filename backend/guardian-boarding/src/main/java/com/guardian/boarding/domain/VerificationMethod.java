package com.guardian.boarding.domain;

/**
 * How the crew established that this is the right child (BR-BOARD-002).
 *
 * <p>Recorded on every event and never defaulted, because the methods are not equally strong and
 * an investigation needs to know which one was used. {@code VISUAL} — the attendant recognised
 * them — is a real and common answer in this market, and recording it honestly is better than
 * recording a scan that did not happen.
 */
public enum VerificationMethod {
  /** A code on the child's card or app, scanned. */
  QR_SCAN,
  /** An RFID or NFC card, tapped. */
  CARD,
  /** Selected from the manifest by the crew. */
  MANUAL,
  /** A one-time code the guardian presented (P-12). */
  OTP,
  /** The crew recognised the child. Honest, and the weakest of the five. */
  VISUAL
}
