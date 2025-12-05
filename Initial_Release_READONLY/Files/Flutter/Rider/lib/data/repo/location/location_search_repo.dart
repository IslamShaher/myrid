import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import '../../../core/utils/method.dart';
import '../../../environment.dart';
import '../../model/location/prediction.dart';

class LocationSearchRepo {
  final ApiClient apiClient;

  LocationSearchRepo({required this.apiClient});

  /// ✅ Detect country code (with Google API fallback via apiClient)
  Future<String?> detectCountryCode(Position position) async {
    String? code;

    // Native reverse geocode
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      code = placemarks.first.isoCountryCode?.toLowerCase();
    } catch (_) {}

    // Fallback with Google Geocoding API if null or empty
    if (code == null || code.trim().isEmpty || code.isEmpty) {
      try {
        final url = '${UrlContainer.googleMapLocationSearch}/geocode/json?latlng=${position.latitude},${position.longitude}&key=${Environment.mapKey}';

        final response = await apiClient.request(url, Method.getMethod, null);

        if (response.statusCode == 200) {
          final data = response.responseJson;
          if (data['status'] == 'OK' && data['results'] != null) {
            for (final result in data['results']) {
              for (final comp in result['address_components']) {
                if ((comp['types'] as List).contains('country')) {
                  code = comp['short_name'].toString().toLowerCase();
                  break;
                }
              }
              if (code != null && code.isNotEmpty) break;
            }
          }
        }
      } catch (_) {}
    }

    // 3️⃣ Return default if nothing found
    return code ?? Environment.defaultCountryCode;
  }

  /// ✅ Get address from lat/lng (Google Geocode API)
  Future<String?> getActualAddress(double lat, double lng) async {
    final url = '${UrlContainer.googleMapLocationSearch}/geocode/json?latlng=$lat,$lng&key=${Environment.mapKey}';

    final response = await apiClient.request(url, Method.getMethod, null);

    if (response.statusCode == 200) {
      final data = response.responseJson;
      if (data['results'] != null && data['results'].isNotEmpty) {
        for (var result in data['results']) {
          final types = result['types'];
          if (types != null && (types.contains('street_address') || types.contains('premise') || types.contains('subpremise') || types.contains('route') || types.contains('locality'))) {
            return result['formatted_address'];
          }
        }
        return data['results'][0]['formatted_address'];
      }

      if (data['plus_code']?['compound_code'] != null) {
        return data['plus_code']['compound_code'];
      }
    }

    return null;
  }

  /// ✅ Search address by name (auto country detect + bias)
  Future<dynamic> searchAddressByLocationName({
    required String text,
    required Position? position,
  }) async {
    String? countryCode;

    if (position != null) {
      countryCode = await detectCountryCode(position);
    }

    String url = '${UrlContainer.googleMapLocationSearch}/place/autocomplete/json'
        '?input=$text'
        '&key=${Environment.mapKey}'
        '&language=en';

    if (countryCode != null && countryCode.isNotEmpty) {
      url += '&components=country:$countryCode';
    } else if (position != null) {
      // fallback: bias by user’s coordinates
      url += '&location=${position.latitude},${position.longitude}&radius=200000';
    }

    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }

  /// ✅ Get place details by placeId
  Future<dynamic> getPlaceDetailsFromPlaceId(Prediction prediction) async {
    final url = '${UrlContainer.googleMapLocationSearch}/place/details/json?placeid=${prediction.placeId}&key=${Environment.mapKey}';
    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }
}
