import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/shuttle/shared_ride_match_model.dart';
import 'package:ovorideuser/data/repo/shuttle/shared_ride_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/ride/shared_ride_active_screen.dart';

class SharedRideController extends GetxController {
  SharedRideRepo sharedRideRepo;
  
  // Text Controllers for Inputs (Moved here for easier access)
  final TextEditingController startLatController = TextEditingController();
  final TextEditingController startLngController = TextEditingController();
  final TextEditingController endLatController = TextEditingController();
  final TextEditingController endLngController = TextEditingController();

  SharedRideController({required this.sharedRideRepo});

  bool isLoading = false;
  List<SharedMatch> matches = [];
  bool searched = false;
  
  // Pending/Active Ride Storage
  RideInfo? currentRide;

  @override
  void onInit() {
    super.onInit();
    checkPendingRide();
  }

  Future<void> checkPendingRide() async {
    // We need an endpoint to "get active shared ride" if any.
    // For now, let's assume valid "current ride" is fetched via a specific endpoint 
    // OR we rely on Home API if it returns it.
    // Let's add a method to Repo to fetch "active-shared-ride".
    
    // Quick fix: We can try to use standard RideRepo "active ride" if it distinguishes types,
    // but better to have dedicated one.
    // Creating one now...
    try {
       // Mocking the call or if we implemented `matchSharedRide` to return current ride?
       // Let's implement `getActiveSharedRide` in Repo.
       ResponseModel response = await sharedRideRepo.getActiveSharedRide();
       if(response.statusCode == 200 && response.responseJson['data'] != null) {
          currentRide = RideInfo.fromJson(response.responseJson['data']);
          update();
       }
    } catch(e) {
      print(e);
    }
  }

  Future<void> matchSharedRide({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String pickupLocation,
    required String destination,
  }) async {
    isLoading = true;
    searched = true;
    update();

    try {
      ResponseModel responseModel = await sharedRideRepo.matchSharedRide(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );

      if (responseModel.statusCode == 200) {
        SharedRideMatchModel model = SharedRideMatchModel.fromJson(responseModel.responseJson);
        matches = model.matches ?? [];
        
        if (matches.isEmpty) {
          // "create new ride if no matches automatically"
          CustomSnackBar.success(successList: ["No matches found. Creating a new ride request for you..."]);
          await createSharedRide(
            startLat: startLat, 
            startLng: startLng, 
            endLat: endLat, 
            endLng: endLng, 
            pickupLocation: pickupLocation, 
            destination: destination
          );
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

  Future<void> joinRide(String rideId) async {
    isLoading = true;
    update();

    try {
      ResponseModel responseModel = await sharedRideRepo.joinRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
         CustomSnackBar.success(successList: ["You joined the ride!"]);
         String rId = responseModel.responseJson['ride']['id'].toString();
         Get.to(() => SharedRideActiveScreen(rideId: rId));
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch(e) {
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> createSharedRide({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String pickupLocation,
    required String destination,
  }) async {
    isLoading = true;
    update();
    
    try {
      ResponseModel responseModel = await sharedRideRepo.createSharedRide(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        pickupLocation: pickupLocation,
        destination: destination,
      );
      
      if (responseModel.statusCode == 200) {
        String rId = responseModel.responseJson['ride']['id'].toString();
        CustomSnackBar.success(successList: ["Ride created! Waiting for a match."]);
        Get.to(() => RideDetailsScreen(rideId: rId));
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch(e) {
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
    } finally {
      isLoading = false;
      update();
    }
  }
}
