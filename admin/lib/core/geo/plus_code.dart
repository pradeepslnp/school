/// Decodes Open Location Codes ("Plus Codes") to coordinates.
///
/// A school's location drives geofence entry, which is what generates its approach and
/// arrival notifications (BR-ALERT-001) — so this exists to make that location *easier to
/// enter correctly*, never to approximate it. A Plus Code is a lossless encoding of a
/// latitude/longitude box: an 11-character code resolves to roughly 3 × 3 m, well inside the
/// smallest geofence radius the platform accepts.
///
/// ## Why this is implemented here rather than taken from a package
///
/// Only decoding is needed, it is a closed specification that does not change, and the value
/// it produces is safety-relevant. Implemented here it can be checked directly against
/// Google's own published decoding vectors
/// (`github.com/google/open-location-code/test_data/decoding.csv`), which is what was done
/// when it was written. Encoding, shortening, and recovery of short codes relative to a
/// reference location are deliberately absent — nothing in this console needs them, and code
/// that is not needed is code that is not checked.
///
/// ## What is deliberately not supported
///
/// **Short codes** (`9G8F+6W Zurich`) are rejected. They are only meaningful relative to a
/// reference location, and guessing that reference is exactly how a school ends up plotted in
/// the wrong country. The operator is asked for a full code instead.
library;

/// A decoded Plus Code: the centre of the box the code names, and how large that box is.
class PlusCodeLocation {
  const PlusCodeLocation({
    required this.latitude,
    required this.longitude,
    required this.precisionMetres,
  });

  final double latitude;
  final double longitude;

  /// Approximate edge length of the decoded box, in metres, for the shorter dimension.
  ///
  /// Shown to the operator so "this code is only accurate to 275 m" is visible before it is
  /// used as the centre of a 150 m geofence.
  final int precisionMetres;
}

/// Decodes full Open Location Codes.
abstract final class PlusCode {
  const PlusCode._();

  /// The code alphabet, in value order. Deliberately excludes vowels and characters that are
  /// easily confused, which is what makes a code readable over a phone.
  static const String _alphabet = '23456789CFGHJMPQRVWX';

  static const String _separator = '+';
  static const int _separatorPosition = 8;
  static const String _padding = '0';

  /// Digits before the separator use base 20 over a 20°×20° starting grid.
  static const double _latitudeMax = 90;
  static const double _longitudeMax = 180;

  /// After 10 digits the encoding switches to a 4×5 grid refinement per character.
  static const int _pairCodeLength = 10;
  static const int _gridRows = 5;
  static const int _gridColumns = 4;
  static const int _maxCodeLength = 15;

  /// Whether [code] is a full code this class can decode.
  static bool isValid(String code) => _normalise(code) != null;

  /// Decodes [code], or returns null when it is not a valid full code.
  ///
  /// Null rather than throwing: the caller is a text field reacting to every keystroke, where
  /// a half-typed code is the normal case rather than an error.
  static PlusCodeLocation? decode(String code) {
    final normalised = _normalise(code);
    if (normalised == null) return null;

    // Resolution halves per pair of digits: 20° for the first pair, then /20 each time.
    double resolution = 20;
    double latitude = -_latitudeMax;
    double longitude = -_longitudeMax;

    final digits = normalised.length < _pairCodeLength
        ? normalised.length
        : _pairCodeLength;

    for (var i = 0; i < digits; i += 2) {
      latitude += _alphabet.indexOf(normalised[i]) * resolution;
      longitude += _alphabet.indexOf(normalised[i + 1]) * resolution;
      if (i < digits - 2) resolution /= 20;
    }

    double latitudePrecision = resolution;
    double longitudePrecision = resolution;

    // Characters beyond the tenth refine within the last cell on a 4-wide, 5-tall grid.
    if (normalised.length > _pairCodeLength) {
      double rowPrecision = resolution / _gridRows;
      double columnPrecision = resolution / _gridColumns;

      for (var i = _pairCodeLength; i < normalised.length; i++) {
        final value = _alphabet.indexOf(normalised[i]);
        latitude += (value ~/ _gridColumns) * rowPrecision;
        longitude += (value % _gridColumns) * columnPrecision;

        if (i < normalised.length - 1) {
          rowPrecision /= _gridRows;
          columnPrecision /= _gridColumns;
        }
      }

      latitudePrecision = rowPrecision;
      longitudePrecision = columnPrecision;
    }

    // The centre of the box, not its corner: a corner would place the school systematically
    // off to one side of where the operator pointed.
    final centreLatitude = latitude + latitudePrecision / 2;
    final centreLongitude = longitude + longitudePrecision / 2;

    return PlusCodeLocation(
      latitude: _clampLatitude(centreLatitude),
      longitude: _clampLongitude(centreLongitude),
      precisionMetres: _metresOf(latitudePrecision, longitudePrecision, centreLatitude),
    );
  }

  /// Upper-cased, separator- and padding-stripped digits, or null when [code] is not a valid
  /// full code.
  static String? _normalise(String code) {
    final trimmed = code.trim().toUpperCase();

    final separator = trimmed.indexOf(_separator);
    if (separator != _separatorPosition) return null;
    if (trimmed.indexOf(_separator, separator + 1) != -1) return null;
    if (trimmed.length > _separatorPosition + 1 &&
        trimmed.length < _separatorPosition + 3) {
      // A single character after the separator is never valid.
      return null;
    }

    final padding = trimmed.indexOf(_padding);
    if (padding != -1) {
      // Padding only ever runs up to the separator, in pairs, and nothing may follow it.
      if (padding < 2 || padding.isOdd) return null;
      if (trimmed.length > _separatorPosition + 1) return null;
      final padded = trimmed.substring(padding, _separatorPosition);
      if (padded.split('').any((character) => character != _padding)) return null;
    }

    var digits = trimmed.replaceAll(_separator, '').replaceAll(_padding, '');
    if (digits.isEmpty || digits.length.isOdd && digits.length < 2) return null;
    if (digits.split('').any((character) => !_alphabet.contains(character))) {
      return null;
    }

    // Digits past the fifteenth are valid but carry no further precision, so the
    // specification ignores them. Truncating rather than rejecting matters in practice: a
    // code pasted from a source that appends extra characters would otherwise be reported to
    // the operator as invalid when it is simply longer than useful.
    if (digits.length > _maxCodeLength) {
      digits = digits.substring(0, _maxCodeLength);
    }

    // The first digit caps latitude at ±90 and the second longitude at ±180; a code whose
    // leading digits exceed those is syntactically well-formed but names nowhere.
    if (_alphabet.indexOf(digits[0]) * 20 - _latitudeMax >= _latitudeMax) return null;
    if (digits.length > 1 &&
        _alphabet.indexOf(digits[1]) * 20 - _longitudeMax >= _longitudeMax) {
      return null;
    }

    return digits;
  }

  static double _clampLatitude(double latitude) =>
      latitude < -_latitudeMax
          ? -_latitudeMax
          : (latitude > _latitudeMax ? _latitudeMax : latitude);

  static double _clampLongitude(double longitude) =>
      longitude < -_longitudeMax
          ? -_longitudeMax
          : (longitude > _longitudeMax ? _longitudeMax : longitude);

  /// The box's shorter edge in metres, rounded up — a deliberately conservative figure, since
  /// it is shown to an operator deciding whether a code is precise enough for a geofence.
  static int _metresOf(
    double latitudeDegrees,
    double longitudeDegrees,
    double atLatitude,
  ) {
    const double metresPerDegreeLatitude = 111320;
    final latitudeMetres = latitudeDegrees * metresPerDegreeLatitude;
    // Longitude degrees narrow towards the poles; at the equator the two are comparable.
    final longitudeMetres = longitudeDegrees * metresPerDegreeLatitude;
    final smaller = latitudeMetres < longitudeMetres
        ? latitudeMetres
        : longitudeMetres;
    return smaller.ceil();
  }
}
