import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/repo/location/location_search_repo.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class AppLocationController extends GetxController {
  LocationSearchRepo locationSearchRepo = LocationSearchRepo(apiClient: Get.find());
  Position currentPosition = MyUtils.getDefaultPosition();
  String currentAddress = "${MyStrings.loading.tr}...";
  Position? position;
  Future<Position?> getCurrentPosition() async {
    try {
      final geolocator = GeolocatorPlatform.instance;

      final position = await geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      this.position = position;

      if (Environment.addressPickerFromGoogleMapApi) {
        currentAddress = await locationSearchRepo.getActualAddress(position.latitude, position.longitude) ?? 'Unknown location..';
      } else {
        // Use local reverse geocoding
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          currentAddress = _formatAddress(placemarks.first);
        } else {
          currentAddress = 'Unknown location..';
        }
      }

      currentPosition = position;
      update();

      printX('appLocations position: $currentAddress');
      return position;
    } catch (e) {
      CustomSnackBar.error(errorList: [MyStrings.locationPermissionNeedMSG.tr]);
    }

    return null;
  }

  /// Format address from placemark components
  String _formatAddress(Placemark placemark) {
    // Safely format address components, checking for nulls
    final street = placemark.street ?? '';
    final subLocality = placemark.subLocality ?? '';
    final locality = placemark.locality ?? '';
    // final subAdministrativeArea = placemark.subAdministrativeArea ?? '';
    // final administrativeArea = placemark.administrativeArea ?? '';
    final country = placemark.country ?? '';

    // return [street, subLocality, locality, subAdministrativeArea, administrativeArea, country].where((part) => part.isNotEmpty).join(', ');
    return [street, subLocality, locality, country].where((part) => part.isNotEmpty).join(', ');
  }
}
