import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/shuttle/shared_ride_match_model.dart';
import 'package:ovorideuser/data/repo/shuttle/shared_ride_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/ride/ride_details_screen.dart';

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
  List<Map<String, dynamic>> pendingRides = [];
  List<Map<String, dynamic>> confirmedRides = [];
  bool isLoadingPendingRides = false;
  bool isLoadingConfirmedRides = false;

  @override
  void onInit() {
    super.onInit();
    checkPendingRide();
    loadPendingAndConfirmedRides();
  }

  Future<void> loadPendingAndConfirmedRides() async {
    await loadPendingRides();
    await loadConfirmedRides();
  }

  Future<void> loadPendingRides() async {
    isLoadingPendingRides = true;
    update();
    
    try {
      ResponseModel response = await sharedRideRepo.getPendingSharedRides();
      if (response.statusCode == 200 && response.responseJson['rides'] != null) {
        pendingRides = List<Map<String, dynamic>>.from(response.responseJson['rides']);
      } else {
        pendingRides = [];
      }
    } catch (e) {
      print("Error loading pending rides: $e");
      pendingRides = [];
    } finally {
      isLoadingPendingRides = false;
      update();
    }
  }

  Future<void> loadConfirmedRides() async {
    isLoadingConfirmedRides = true;
    update();
    
    try {
      ResponseModel response = await sharedRideRepo.getConfirmedSharedRides();
      if (response.statusCode == 200 && response.responseJson['rides'] != null) {
        confirmedRides = List<Map<String, dynamic>>.from(response.responseJson['rides']);
      } else {
        confirmedRides = [];
      }
    } catch (e) {
      print("Error loading confirmed rides: $e");
      confirmedRides = [];
    } finally {
      isLoadingConfirmedRides = false;
      update();
    }
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

  DateTime? selectedScheduledTime;
  
  Future<void> matchSharedRide({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String pickupLocation,
    required String destination,
    DateTime? scheduledTime,
  }) async {
    print("matchSharedRide called with: $startLat, $startLng to $endLat, $endLng");
    isLoading = true;
    searched = true;
    update();

    try {
      print("Sending request to matchSharedRide...");
      ResponseModel responseModel = await sharedRideRepo.matchSharedRide(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );

      print("Response status: ${responseModel.statusCode}");
      print("Response body: ${responseModel.responseJson}");

      if (responseModel.statusCode == 200) {
        SharedRideMatchModel model = SharedRideMatchModel.fromJson(responseModel.responseJson);
        matches = model.matches ?? [];
        print("Found ${matches.length} matches");
        
        if (matches.isEmpty) {
          // "create new ride if no matches automatically"
          CustomSnackBar.success(successList: ["No matches found. Creating a new ride request for you..."]);
          print("No matches, creating shared ride...");
          await createSharedRide(
            startLat: startLat, 
            startLng: startLng, 
            endLat: endLat, 
            endLng: endLng, 
            pickupLocation: pickupLocation, 
            destination: destination,
            scheduledTime: scheduledTime,
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      print("Error in matchSharedRide: $e");
      CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> joinRide(String rideId, {double? startLat, double? startLng, double? endLat, double? endLng}) async {
    isLoading = true;
    update();

    try {
      // Use provided coordinates or fallback to controller values
      double? sLat = startLat ?? double.tryParse(startLatController.text);
      double? sLng = startLng ?? double.tryParse(startLngController.text);
      double? eLat = endLat ?? double.tryParse(endLatController.text);
      double? eLng = endLng ?? double.tryParse(endLngController.text);
      
      ResponseModel responseModel = await sharedRideRepo.joinRide(
        rideId: rideId,
        startLat: sLat,
        startLng: sLng,
        endLat: eLat,
        endLng: eLng,
      );
      if (responseModel.statusCode == 200) {
         CustomSnackBar.success(successList: ["You joined the ride!"]);
         String rId = responseModel.responseJson['ride']['id'].toString();
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

  Future<void> createSharedRide({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String pickupLocation,
    required String destination,
    DateTime? scheduledTime,
  }) async {
    isLoading = true;
    update();
    
    try {
      bool isScheduled = scheduledTime != null;
      String? scheduledTimeStr = scheduledTime?.toIso8601String();
      ResponseModel responseModel = await sharedRideRepo.createSharedRide(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
        pickupLocation: pickupLocation,
        destination: destination,
        isScheduled: isScheduled,
        scheduledTime: scheduledTimeStr,
      );
      
      if (responseModel.statusCode == 200) {
        String rId = responseModel.responseJson['ride']['id'].toString();
        bool shouldReturnToHome = responseModel.responseJson['should_return_to_home'] ?? false;
        String message = responseModel.responseJson['message'] ?? "Ride created! Waiting for a match.";
        
        CustomSnackBar.success(successList: [message]);
        
        if (shouldReturnToHome) {
          // Return to home screen for scheduled rides
          Get.back();
        } else {
          // Navigate to ride details for immediate rides
          Get.to(() => RideDetailsScreen(rideId: rId));
        }
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
