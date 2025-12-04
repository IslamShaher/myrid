import 'package:get/get.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/data/model/global/response_model/response_model.dart';
import 'package:ovoride_driver/data/repo/shuttle/shuttle_driver_repo.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';

class ShuttleDriverController extends GetxController {
  ShuttleDriverRepo repo;
  ShuttleDriverController({required this.repo});

  bool isLoading = false;
  List<dynamic> routes = [];
  
  // Active Trip State
  int? activeRouteId;
  Map<String, dynamic>? currentRouteData;
  
  Future<void> loadRoutes() async {
    isLoading = true;
    update();
    
    ResponseModel model = await repo.getRoutes();
    if(model.statusCode == 200) {
      routes = model.responseJson['data']['routes'];
    } else {
      CustomSnackBar.error(errorList: [model.message]);
    }
    
    isLoading = false;
    update();
  }

  Future<void> startTrip(int routeId) async {
    isLoading = true;
    update();
    ResponseModel model = await repo.startTrip(routeId);
    if(model.statusCode == 200) {
      CustomSnackBar.success(successList: [model.message]);
      
      // Find route data to pass to trip screen
      currentRouteData = routes.firstWhere((element) => element['id'] == routeId);
      activeRouteId = routeId;
      
      Get.toNamed(RouteHelper.shuttleTripScreen);
    } else {
      CustomSnackBar.error(errorList: [model.message]);
    }
    isLoading = false;
    update();
  }
  
  Future<void> arriveAtStop(int stopId) async {
    if(activeRouteId == null) return;
    
    isLoading = true;
    update();
    ResponseModel model = await repo.arriveAtStop(activeRouteId!, stopId);
    if(model.statusCode == 200) {
      CustomSnackBar.success(successList: [model.message]);
    } else {
      CustomSnackBar.error(errorList: [model.message]);
    }
    isLoading = false;
    update();
  }
  
  Future<void> departStop(int stopId) async {
    if(activeRouteId == null) return;
    
    isLoading = true;
    update();
    ResponseModel model = await repo.departStop(activeRouteId!, stopId);
    if(model.statusCode == 200) {
      CustomSnackBar.success(successList: [model.message]);
    } else {
      CustomSnackBar.error(errorList: [model.message]);
    }
    isLoading = false;
    update();
  }
}
