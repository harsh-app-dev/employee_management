class ParsedLocation {
  final String? street;
  final String? city;
  final String? state;
  final String? country;

  ParsedLocation({
    this.street,
    this.city,
    this.state,
    this.country,
  });

  factory ParsedLocation.fromString(String? location) {
    if (location == null || location.isEmpty) {
      return ParsedLocation();
    }

    final parts = location.split(', ');
    return ParsedLocation(
      street: parts.length > 0 ? parts[0] : null,
      city: parts.length > 1 ? parts[1] : null,
      state: parts.length > 2 ? parts[2] : null,
      country: parts.length > 3 ? parts[3] : null,
    );
  }

  String formatShort() => [city, state].where((e) => e != null).join(', ');
  String formatMedium() => [street, city, state].where((e) => e != null).join(', ');
  String formatLong() => [street, city, state, country].where((e) => e != null).join(', ');
}