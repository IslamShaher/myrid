import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/shuttle/shuttle_route_model.dart';
import 'package:ovorideuser/data/repo/shuttle/shuttle_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ShuttleController extends GetxController {
  ShuttleRepo shuttleRepo;
  ShuttleController({required this.shuttleRepo});

  bool isLoading = false;
  ShuttleRouteModel? shuttleRouteModel;
  MatchedRoute? selectedRoute;

  Future<void> matchRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    isLoading = true;
    update();

    try {
      ResponseModel responseModel = await shuttleRepo.matchRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );

      if (responseModel.statusCode == 200) {
        shuttleRouteModel = ShuttleRouteModel.fromJson(responseModel.responseJson);
        if (shuttleRouteModel?.matchedRoutes?.isEmpty ?? true) {
          CustomSnackBar.error(errorList: [MyStrings.noRouteFound.tr]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
    } finally {
      isLoading = false;
      update();
    }
  }

  void selectRoute(MatchedRoute route) {
    selectedRoute = route;
    update();
  }
  
  void clearData() {
    shuttleRouteModel = null;
    selectedRoute = null;
    update();
  }
}
