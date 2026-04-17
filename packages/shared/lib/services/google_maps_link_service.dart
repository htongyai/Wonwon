import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:shared/utils/app_logger.dart';

/// Rich result from parsing a Google Maps URL.
/// Contains everything we could extract from the URL, geocoding, and Places API.
class GoogleMapsLinkResult {
  // Core location
  final double latitude;
  final double longitude;

  // Identity
  final String? placeName;
  final String? placeId;

  // Address components
  final String? fullAddress;
  final String? street;
  final String? buildingNumber;
  final String? buildingName;
  final String? district;
  final String? subDistrict;
  final String? province;
  final String? postalCode;
  final String? landmark;

  // Contact info (from Places API)
  final String? phoneNumber;
  final String? website;

  // Business details (from Places API)
  final List<String>? businessTypes;
  final List<String>? matchedCategories;

  // Opening hours (from Places API)
  /// Day index (0=Sunday, 1=Monday, ..., 6=Saturday) to opening/closing times
  final Map<int, PlaceOpeningPeriod>? openingHours;
  final List<String>? weekdayDescriptions;

  // Photos (from Places API)
  final List<String>? photoUrls;

  const GoogleMapsLinkResult({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.placeId,
    this.fullAddress,
    this.street,
    this.buildingNumber,
    this.buildingName,
    this.district,
    this.subDistrict,
    this.province,
    this.postalCode,
    this.landmark,
    this.phoneNumber,
    this.website,
    this.businessTypes,
    this.matchedCategories,
    this.openingHours,
    this.weekdayDescriptions,
    this.photoUrls,
  });

  /// How many fields were successfully extracted
  int get extractedFieldCount {
    int count = 2; // lat/lng always present
    if (placeName != null) count++;
    if (fullAddress != null) count++;
    if (street != null) count++;
    if (buildingNumber != null) count++;
    if (district != null) count++;
    if (province != null) count++;
    if (phoneNumber != null) count++;
    if (website != null) count++;
    if (openingHours != null && openingHours!.isNotEmpty) count++;
    if (matchedCategories != null && matchedCategories!.isNotEmpty) count++;
    return count;
  }

  @override
  String toString() =>
      'GoogleMapsLinkResult(lat: $latitude, lng: $longitude, name: $placeName, '
      'phone: $phoneNumber, district: $district, province: $province, '
      'fields: $extractedFieldCount)';
}

/// Opening/closing time for a single day
class PlaceOpeningPeriod {
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;
  final bool isClosed;

  const PlaceOpeningPeriod({
    this.openHour = 0,
    this.openMinute = 0,
    this.closeHour = 0,
    this.closeMinute = 0,
    this.isClosed = false,
  });

  const PlaceOpeningPeriod.closed()
      : openHour = 0,
        openMinute = 0,
        closeHour = 0,
        closeMinute = 0,
        isClosed = true;

  String get openTimeFormatted =>
      '${openHour.toString().padLeft(2, '0')}:${openMinute.toString().padLeft(2, '0')}';
  String get closeTimeFormatted =>
      '${closeHour.toString().padLeft(2, '0')}:${closeMinute.toString().padLeft(2, '0')}';
}

/// Service for parsing Google Maps URLs (full and shortened) to extract
/// latitude, longitude, place name, phone, hours, categories, and address.
///
/// Data sources (in order of richness):
/// 1. URL parsing — coordinates, place name, place ID
/// 2. Enhanced Nominatim — street, building, district, province, postal code
/// 3. Google Places API (New) — phone, hours, website, business types, photos
///
/// Supported URL formats:
/// - `https://www.google.com/maps/place/Shop+Name/@lat,lng,17z/...`
/// - `https://www.google.com/maps/@lat,lng,17z`
/// - `https://maps.google.com/maps?q=lat,lng`
/// - `https://www.google.com/maps/search/query/@lat,lng`
/// - `https://goo.gl/maps/xxxx` (shortened)
/// - `https://maps.app.goo.gl/xxxx` (shortened)
class GoogleMapsLinkService {
  static final GoogleMapsLinkService _instance =
      GoogleMapsLinkService._internal();
  factory GoogleMapsLinkService() => _instance;
  GoogleMapsLinkService._internal();

  /// The Google Maps API key — reads from the hardcoded key used across the app.
  /// In production this should come from environment variables.
  static const String _googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBJE-vqPz0YakKEmj1qi14tk1LUTGBFFPA',
  );

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    followRedirects: false,
    // Accept all 2xx and 3xx (redirect) status codes
    validateStatus: (status) => status != null && status < 400,
  ));

  /// Reusable Dio for general API calls (geocoding, Places API)
  final Dio _apiDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Optional Cloud Function URL for resolving shortened URLs on web.
  /// Set this to your deployed Firebase Function URL.
  /// Example: 'https://us-central1-YOUR-PROJECT.cloudfunctions.net/resolveShortUrl'
  static const String _resolveUrlFunctionUrl = String.fromEnvironment(
    'RESOLVE_URL_FUNCTION',
    defaultValue: '',
  );

  /// Check if a string looks like a Google Maps URL
  static bool isGoogleMapsUrl(String text) {
    final trimmed = text.trim();
    return trimmed.contains('google.com/maps') ||
        trimmed.contains('google.co.th/maps') ||
        trimmed.contains('maps.google.com') ||
        trimmed.contains('goo.gl/maps') ||
        trimmed.contains('maps.app.goo.gl') ||
        trimmed.contains('maps.google.co.th');
  }

  /// Check if a URL is a shortened Google Maps URL
  static bool isShortenedUrl(String text) {
    final trimmed = text.trim();
    return trimmed.contains('goo.gl/maps') || trimmed.contains('maps.app.goo.gl');
  }

  /// Parse a Google Maps URL and extract as much data as possible.
  /// Returns null only if coordinates cannot be extracted.
  Future<GoogleMapsLinkResult?> parseUrl(String url) async {
    try {
      String fullUrl = url.trim();

      // Step 1: Resolve shortened URLs
      if (_isShortenedUrl(fullUrl)) {
        final resolved = await _resolveShortUrl(fullUrl);
        if (resolved == null) return null;
        fullUrl = resolved;
      }

      // Step 2: Extract coordinates from URL
      final coords = _extractCoordinates(fullUrl);
      if (coords == null) return null;

      final lat = coords.$1;
      final lng = coords.$2;

      // Validate coordinates
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

      // Step 3: Extract what we can from the URL itself
      String? placeName = _extractPlaceName(fullUrl);
      String? placeId = _extractPlaceId(fullUrl);

      // Step 4: Enhanced geocoding (Nominatim + native)
      String? fullAddress;
      String? street;
      String? buildingNumber;
      String? buildingName;
      String? district;
      String? subDistrict;
      String? province;
      String? postalCode;
      String? landmark;

      // Try Nominatim first (richer data for Thailand)
      final nominatimResult = await _reverseGeocodeNominatim(lat, lng);
      if (nominatimResult != null) {
        fullAddress = nominatimResult['display_name'];
        street = nominatimResult['road'];
        buildingNumber = nominatimResult['house_number'];
        buildingName = nominatimResult['building'];
        district = nominatimResult['district'];
        subDistrict = nominatimResult['sub_district'];
        province = nominatimResult['province'];
        postalCode = nominatimResult['postcode'];
        landmark = nominatimResult['landmark'];
      }

      // Fallback to native geocoding if Nominatim missed key fields
      if (district == null || province == null) {
        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            district ??= pm.subLocality ?? pm.locality;
            province ??= pm.administrativeArea;
            street ??= pm.street;
            postalCode ??= pm.postalCode;
            if (fullAddress == null) {
              final parts = <String>[
                if (pm.street != null && pm.street!.isNotEmpty) pm.street!,
                if (pm.subLocality != null && pm.subLocality!.isNotEmpty)
                  pm.subLocality!,
                if (pm.locality != null && pm.locality!.isNotEmpty)
                  pm.locality!,
                if (pm.administrativeArea != null &&
                    pm.administrativeArea!.isNotEmpty)
                  pm.administrativeArea!,
              ];
              if (parts.isNotEmpty) fullAddress = parts.join(', ');
            }
          }
        } catch (_) {
          // Native geocoding not available (common on web)
        }
      }

      // Step 5: Google Places API for business details
      String? phoneNumber;
      String? website;
      List<String>? businessTypes;
      List<String>? matchedCategories;
      Map<int, PlaceOpeningPeriod>? openingHours;
      List<String>? weekdayDescriptions;
      List<String>? photoUrls;

      final placesData =
          await _fetchPlacesApiData(lat, lng, placeName, placeId);
      if (placesData != null) {
        // Use Places API name if we didn't get one from URL, or if Places gives a better one
        if (placesData['name'] != null) {
          final apiName = placesData['name'] as String;
          if (placeName == null || apiName.length > placeName.length) {
            placeName = apiName;
          }
        }
        phoneNumber = placesData['phone'] as String?;
        website = placesData['website'] as String?;
        businessTypes = (placesData['types'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        matchedCategories = _mapBusinessTypesToCategories(businessTypes);
        openingHours =
            placesData['opening_hours'] as Map<int, PlaceOpeningPeriod>?;
        weekdayDescriptions = (placesData['weekday_descriptions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        photoUrls = (placesData['photo_urls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

        // Places API may give a better address
        if (placesData['address'] != null) {
          fullAddress = placesData['address'] as String;
        }

        // Places API address components can fill gaps
        if (placesData['address_components'] != null) {
          final components =
              placesData['address_components'] as Map<String, String>;
          street ??= components['route'];
          buildingNumber ??= components['street_number'];
          district ??= components['sublocality'] ?? components['locality'];
          province ??= components['administrative_area_level_1'];
          postalCode ??= components['postal_code'];
        }
      }

      return GoogleMapsLinkResult(
        latitude: lat,
        longitude: lng,
        placeName: placeName,
        placeId: placeId,
        fullAddress: fullAddress,
        street: street,
        buildingNumber: buildingNumber,
        buildingName: buildingName,
        district: district,
        subDistrict: subDistrict,
        province: province,
        postalCode: postalCode,
        landmark: landmark,
        phoneNumber: phoneNumber,
        website: website,
        businessTypes: businessTypes,
        matchedCategories: matchedCategories,
        openingHours: openingHours,
        weekdayDescriptions: weekdayDescriptions,
        photoUrls: photoUrls,
      );
    } catch (e) {
      appLog('GoogleMapsLinkService: Failed to parse URL: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // URL Parsing
  // ─────────────────────────────────────────────────────────────────────

  bool _isShortenedUrl(String url) {
    return url.contains('goo.gl/maps') || url.contains('maps.app.goo.gl');
  }

  Future<String?> _resolveShortUrl(String shortUrl) async {
    // On web, try Cloud Function first (CORS blocks direct redirect following)
    if (kIsWeb) {
      final resolved = await _resolveViaCloudFunction(shortUrl);
      if (resolved != null) return resolved;
      // On web without Cloud Function, we can't resolve shortened URLs
      appLog('GoogleMapsLinkService: Cannot resolve short URL on web (CORS). '
          'Deploy the resolveShortUrl Cloud Function or use a full Google Maps URL.');
      return null;
    }

    // On mobile — follow redirects directly
    try {
      String currentUrl = shortUrl;

      for (int i = 0; i < 5; i++) {
        final response = await _dio.get(
          currentUrl,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; WonWonApp/1.0)',
            },
          ),
        );

        final statusCode = response.statusCode ?? 0;

        if (statusCode >= 301 && statusCode <= 308) {
          final location = response.headers.value('location');
          if (location == null || location.isEmpty) return null;

          if (location.startsWith('/')) {
            final uri = Uri.parse(currentUrl);
            currentUrl = '${uri.scheme}://${uri.host}$location';
          } else {
            currentUrl = location;
          }

          if (currentUrl.contains('google.com/maps') ||
              currentUrl.contains('google.co.th/maps')) {
            return currentUrl;
          }
        } else {
          final realUri = response.realUri.toString();
          if (realUri.contains('google.com/maps') ||
              realUri.contains('google.co.th/maps')) {
            return realUri;
          }
          return currentUrl;
        }
      }
      return currentUrl;
    } catch (e) {
      try {
        final dio2 = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          followRedirects: true,
          maxRedirects: 5,
        ));
        final response = await dio2.get(
          shortUrl,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; WonWonApp/1.0)',
            },
          ),
        );
        return response.realUri.toString();
      } catch (e2) {
        appLog('GoogleMapsLinkService: Failed to resolve short URL: $e2');
        return null;
      }
    }
  }

  /// Try to resolve a shortened URL via a deployed Cloud Function.
  /// Returns null if the function is not configured or fails.
  Future<String?> _resolveViaCloudFunction(String shortUrl) async {
    if (_resolveUrlFunctionUrl.isEmpty) return null;

    try {
      final response = await _apiDio.get(
        _resolveUrlFunctionUrl,
        queryParameters: {'url': shortUrl},
      );

      if (response.statusCode == 200 && response.data != null) {
        final resolvedUrl = response.data['resolvedUrl'] as String?;
        if (resolvedUrl != null &&
            (resolvedUrl.contains('google.com/maps') ||
                resolvedUrl.contains('google.co.th/maps'))) {
          return resolvedUrl;
        }
      }
    } catch (e) {
      appLog('GoogleMapsLinkService: Cloud Function resolve failed: $e');
    }
    return null;
  }

  (double, double)? _extractCoordinates(String url) {
    final decodedUrl = Uri.decodeFull(url);

    // Pattern 1: /@lat,lng,zoom
    final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final atMatch = atPattern.firstMatch(decodedUrl);
    if (atMatch != null) {
      final lat = double.tryParse(atMatch.group(1)!);
      final lng = double.tryParse(atMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }

    // Pattern 2: ?q=lat,lng
    final qPattern = RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final qMatch = qPattern.firstMatch(decodedUrl);
    if (qMatch != null) {
      final lat = double.tryParse(qMatch.group(1)!);
      final lng = double.tryParse(qMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }

    // Pattern 3: ?ll=lat,lng
    final llPattern = RegExp(r'[?&]ll=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final llMatch = llPattern.firstMatch(decodedUrl);
    if (llMatch != null) {
      final lat = double.tryParse(llMatch.group(1)!);
      final lng = double.tryParse(llMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }

    // Pattern 4: /dir/.../lat,lng/
    final dirPattern = RegExp(r'/dir/[^/]*/(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final dirMatch = dirPattern.firstMatch(decodedUrl);
    if (dirMatch != null) {
      final lat = double.tryParse(dirMatch.group(1)!);
      final lng = double.tryParse(dirMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }

    // Pattern 5: !3dlat!4dlng (data parameter encoding)
    final dataPattern = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)');
    final dataMatch = dataPattern.firstMatch(decodedUrl);
    if (dataMatch != null) {
      final lat = double.tryParse(dataMatch.group(1)!);
      final lng = double.tryParse(dataMatch.group(2)!);
      if (lat != null && lng != null) return (lat, lng);
    }

    return null;
  }

  String? _extractPlaceName(String url) {
    final decodedUrl = Uri.decodeFull(url);

    // /place/Place+Name/@...
    final placePattern = RegExp(r'/place/([^/@]+)');
    final placeMatch = placePattern.firstMatch(decodedUrl);
    if (placeMatch != null) {
      String name = placeMatch.group(1)!;
      name = name.replaceAll('+', ' ').replaceAll('%20', ' ');
      if (name.contains('/')) name = name.split('/').first;
      if (RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(name.trim())) {
        return null;
      }
      return name.trim().isNotEmpty ? name.trim() : null;
    }

    // /search/Query+Text/@...
    final searchPattern = RegExp(r'/search/([^/@]+)');
    final searchMatch = searchPattern.firstMatch(decodedUrl);
    if (searchMatch != null) {
      String name = searchMatch.group(1)!;
      name = name.replaceAll('+', ' ').replaceAll('%20', ' ');
      if (name.contains('/')) name = name.split('/').first;
      return name.trim().isNotEmpty ? name.trim() : null;
    }

    // ?q=Place+Name (non-coordinate)
    final qPattern = RegExp(r'[?&]q=([^&]+)');
    final qMatch = qPattern.firstMatch(decodedUrl);
    if (qMatch != null) {
      String name = qMatch.group(1)!;
      if (!RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(name.trim())) {
        name = name.replaceAll('+', ' ');
        return name.trim().isNotEmpty ? name.trim() : null;
      }
    }

    return null;
  }

  /// Extract Place ID from Google Maps URL data parameters
  String? _extractPlaceId(String url) {
    final decodedUrl = Uri.decodeFull(url);

    // Pattern: ftid=0x...:0x...
    final ftidPattern = RegExp(r'ftid=(0x[0-9a-f]+:0x[0-9a-f]+)');
    final ftidMatch = ftidPattern.firstMatch(decodedUrl);
    if (ftidMatch != null) return ftidMatch.group(1);

    // Pattern: !1sChIJ... (Place ID in data section)
    final chijPattern = RegExp(r'!1s(ChIJ[A-Za-z0-9_-]+)');
    final chijMatch = chijPattern.firstMatch(decodedUrl);
    if (chijMatch != null) return chijMatch.group(1);

    // Pattern: place_id= query parameter
    final pidPattern = RegExp(r'[?&]place_id=([^&]+)');
    final pidMatch = pidPattern.firstMatch(decodedUrl);
    if (pidMatch != null) return pidMatch.group(1);

    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Enhanced Nominatim Geocoding
  // ─────────────────────────────────────────────────────────────────────

  Future<Map<String, String>?> _reverseGeocodeNominatim(
    double lat,
    double lng,
  ) async {
    try {
      final response = await _apiDio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'th,en',
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'WonWon-App/2.2'},
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final addr = data['address'] as Map<String, dynamic>?;
        final result = <String, String>{};

        result['display_name'] = data['display_name']?.toString() ?? '';

        if (addr != null) {
          // Road / Street
          final road = addr['road'] as String? ??
              addr['pedestrian'] as String? ??
              addr['footway'] as String?;
          if (road != null) result['road'] = road;

          // Building number
          final houseNumber = addr['house_number'] as String?;
          if (houseNumber != null) result['house_number'] = houseNumber;

          // Building name
          final building = addr['building'] as String? ??
              addr['amenity'] as String? ??
              addr['shop'] as String?;
          if (building != null) result['building'] = building;

          // District (multiple possible keys for Thai addresses)
          final district = addr['suburb'] as String? ??
              addr['city_district'] as String? ??
              addr['quarter'] as String?;
          if (district != null) result['district'] = district;

          // Sub-district (Thai: ตำบล/แขวง)
          final subDistrict = addr['village'] as String? ??
              addr['town'] as String? ??
              addr['neighbourhood'] as String?;
          if (subDistrict != null) result['sub_district'] = subDistrict;

          // Province / State
          final province = addr['state'] as String? ??
              addr['province'] as String? ??
              addr['city'] as String? ??
              addr['county'] as String?;
          if (province != null) result['province'] = province;

          // Postal code
          final postcode = addr['postcode'] as String?;
          if (postcode != null) result['postcode'] = postcode;

          // Landmark — nearby notable places
          final landmark = addr['tourism'] as String? ??
              addr['historic'] as String? ??
              addr['leisure'] as String? ??
              addr['natural'] as String?;
          if (landmark != null) result['landmark'] = landmark;
        }

        return result;
      }
    } catch (e) {
      appLog('GoogleMapsLinkService: Nominatim geocoding failed: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Google Places API (New)
  // ─────────────────────────────────────────────────────────────────────

  /// Fetch business details from Google Places API.
  /// Uses Place ID if available, otherwise searches by name + location.
  Future<Map<String, dynamic>?> _fetchPlacesApiData(
    double lat,
    double lng,
    String? placeName,
    String? placeId,
  ) async {
    try {
      if (_googleApiKey.isEmpty) return null;

      Map<String, dynamic>? placeData;

      // Strategy 1: Use Place ID for direct lookup
      if (placeId != null && placeId.startsWith('ChIJ')) {
        placeData = await _getPlaceDetails(placeId);
      }

      // Strategy 2: Search by text near the coordinates
      if (placeData == null && placeName != null && placeName.isNotEmpty) {
        placeData = await _searchPlaceByText(placeName, lat, lng);
      }

      // Strategy 3: Nearby search at exact coordinates
      if (placeData == null) {
        placeData = await _searchNearby(lat, lng);
      }

      return placeData;
    } catch (e) {
      appLog('GoogleMapsLinkService: Places API failed: $e');
      return null;
    }
  }

  /// Get place details by Place ID using Places API (New)
  Future<Map<String, dynamic>?> _getPlaceDetails(
    String placeId,
  ) async {
    try {
      final response = await _apiDio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask':
                'displayName,formattedAddress,nationalPhoneNumber,'
                    'internationalPhoneNumber,regularOpeningHours,'
                    'websiteUri,types,primaryType,addressComponents,'
                    'photos',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parsePlacesApiResponse(response.data);
      }
    } catch (e) {
      appLog('GoogleMapsLinkService: Place details failed: $e');
    }
    return null;
  }

  /// Search for a place by text query near coordinates
  Future<Map<String, dynamic>?> _searchPlaceByText(
    String query,
    double lat,
    double lng,
  ) async {
    try {
      final response = await _apiDio.post(
        'https://places.googleapis.com/v1/places:searchText',
        data: {
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 200.0,
            },
          },
          'maxResultCount': 1,
          'languageCode': 'th',
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,'
                    'places.nationalPhoneNumber,places.internationalPhoneNumber,'
                    'places.regularOpeningHours,places.websiteUri,'
                    'places.types,places.primaryType,'
                    'places.addressComponents,places.photos',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final places = response.data['places'] as List<dynamic>?;
        if (places != null && places.isNotEmpty) {
          return _parsePlacesApiResponse(places.first);
        }
      }
    } catch (e) {
      appLog('GoogleMapsLinkService: Text search failed: $e');
    }
    return null;
  }

  /// Search for nearest place at coordinates
  Future<Map<String, dynamic>?> _searchNearby(
    double lat,
    double lng,
  ) async {
    try {
      final response = await _apiDio.post(
        'https://places.googleapis.com/v1/places:searchNearby',
        data: {
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': 50.0,
            },
          },
          'maxResultCount': 1,
          'languageCode': 'th',
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,'
                    'places.nationalPhoneNumber,places.internationalPhoneNumber,'
                    'places.regularOpeningHours,places.websiteUri,'
                    'places.types,places.primaryType,'
                    'places.addressComponents,places.photos',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final places = response.data['places'] as List<dynamic>?;
        if (places != null && places.isNotEmpty) {
          return _parsePlacesApiResponse(places.first);
        }
      }
    } catch (e) {
      appLog('GoogleMapsLinkService: Nearby search failed: $e');
    }
    return null;
  }

  /// Parse the raw Places API (New) response into a flat map
  Map<String, dynamic> _parsePlacesApiResponse(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    // Name
    final displayName = data['displayName'] as Map<String, dynamic>?;
    if (displayName != null) {
      result['name'] = displayName['text'] as String?;
    }

    // Formatted address
    result['address'] = data['formattedAddress'] as String?;

    // Phone number (prefer national format for Thailand)
    result['phone'] = data['nationalPhoneNumber'] as String? ??
        data['internationalPhoneNumber'] as String?;

    // Website
    result['website'] = data['websiteUri'] as String?;

    // Business types
    final types = data['types'] as List<dynamic>?;
    if (types != null) {
      result['types'] = types.map((e) => e.toString()).toList();
    }

    // Address components
    final addressComponents = data['addressComponents'] as List<dynamic>?;
    if (addressComponents != null) {
      final components = <String, String>{};
      for (final comp in addressComponents) {
        final compMap = comp as Map<String, dynamic>;
        final types = (compMap['types'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final longText = compMap['longText'] as String? ?? '';

        if (types.contains('street_number')) {
          components['street_number'] = longText;
        } else if (types.contains('route')) {
          components['route'] = longText;
        } else if (types.contains('sublocality') ||
            types.contains('sublocality_level_1')) {
          components['sublocality'] = longText;
        } else if (types.contains('locality')) {
          components['locality'] = longText;
        } else if (types.contains('administrative_area_level_1')) {
          components['administrative_area_level_1'] = longText;
        } else if (types.contains('postal_code')) {
          components['postal_code'] = longText;
        }
      }
      result['address_components'] = components;
    }

    // Opening hours
    final regularHours = data['regularOpeningHours'] as Map<String, dynamic>?;
    if (regularHours != null) {
      // Parse periods into our model
      final periods = regularHours['periods'] as List<dynamic>?;
      if (periods != null) {
        final hoursMap = <int, PlaceOpeningPeriod>{};
        for (final period in periods) {
          final periodMap = period as Map<String, dynamic>;
          final open = periodMap['open'] as Map<String, dynamic>?;
          final close = periodMap['close'] as Map<String, dynamic>?;

          if (open != null) {
            final day = open['day'] as int? ?? 0;
            hoursMap[day] = PlaceOpeningPeriod(
              openHour: open['hour'] as int? ?? 0,
              openMinute: open['minute'] as int? ?? 0,
              closeHour: close?['hour'] as int? ?? 0,
              closeMinute: close?['minute'] as int? ?? 0,
            );
          }
        }
        if (hoursMap.isNotEmpty) {
          result['opening_hours'] = hoursMap;
        }
      }

      // Weekday descriptions (human-readable)
      final descriptions =
          regularHours['weekdayDescriptions'] as List<dynamic>?;
      if (descriptions != null) {
        result['weekday_descriptions'] = descriptions;
      }
    }

    // Photos (just the resource names — can construct URLs later)
    final photos = data['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final photoUrls = <String>[];
      for (final photo in photos.take(3)) {
        final photoMap = photo as Map<String, dynamic>;
        final name = photoMap['name'] as String?;
        if (name != null) {
          // Construct the photo URL using the Places API
          photoUrls.add(
            'https://places.googleapis.com/v1/$name/media?maxHeightPx=800&maxWidthPx=800&key=$_googleApiKey',
          );
        }
      }
      if (photoUrls.isNotEmpty) {
        result['photo_urls'] = photoUrls;
      }
    }

    return result;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Category Mapping
  // ─────────────────────────────────────────────────────────────────────

  /// Map Google Places business types to WonWon repair categories
  List<String>? _mapBusinessTypesToCategories(List<String>? types) {
    if (types == null || types.isEmpty) return null;

    final categories = <String>{};
    final typeSet = types.map((t) => t.toLowerCase()).toSet();

    // Clothing
    if (typeSet.any((t) =>
        t.contains('clothing') ||
        t.contains('tailor') ||
        t.contains('dry_clean') ||
        t.contains('laundry') ||
        t.contains('fashion') ||
        t.contains('boutique') ||
        t.contains('alteration'))) {
      categories.add('clothing');
    }

    // Footwear
    if (typeSet.any((t) =>
        t.contains('shoe') ||
        t.contains('cobbler') ||
        t.contains('footwear'))) {
      categories.add('footwear');
    }

    // Watch
    if (typeSet.any((t) =>
        t.contains('watch') ||
        t.contains('jewel') ||
        t.contains('clock') ||
        t.contains('horol'))) {
      categories.add('watch');
    }

    // Bag
    if (typeSet.any((t) =>
        t.contains('bag') ||
        t.contains('luggage') ||
        t.contains('leather') ||
        t.contains('handbag'))) {
      categories.add('bag');
    }

    // Electronics
    if (typeSet.any((t) =>
        t.contains('electronics') ||
        t.contains('phone') ||
        t.contains('mobile') ||
        t.contains('computer') ||
        t.contains('cell_phone') ||
        t.contains('electrical'))) {
      categories.add('electronics');
    }

    // Appliance
    if (typeSet.any((t) =>
        t.contains('appliance') ||
        t.contains('hvac') ||
        t.contains('plumb') ||
        t.contains('home_improvement'))) {
      categories.add('appliance');
    }

    // General repair signals
    if (typeSet.any((t) => t.contains('repair') || t.contains('fix'))) {
      // If we detect "repair" but no specific category, keep what we have
      // The user will need to select the specific category
    }

    return categories.isNotEmpty ? categories.toList() : null;
  }
}
