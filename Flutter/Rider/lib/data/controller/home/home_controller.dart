import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/date_converter.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/model/dashboard/dashboard_response_model.dart';
import 'package:ovorideuser/data/model/global/app/app_payment_method.dart';
import 'package:ovorideuser/data/model/global/app/app_service_model.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/ride/create_ride_request_model.dart';
import 'package:ovorideuser/data/model/global/user/global_user_model.dart';
import 'package:ovorideuser/data/model/ride/create_ride_response_model.dart';
import 'package:ovorideuser/data/model/ride/ride_fare_response_model.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/location/selected_location_info.dart';
import 'package:ovorideuser/data/repo/home/home_repo.dart';
import 'package:ovorideuser/data/services/running_ride_service.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovorideuser/presentation/components/dialog/app_dialog.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/bottomsheet/ride_distance_warning_bottom_sheet.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';

class HomeController extends GetxController {
  HomeRepo homeRepo;
  AppLocationController appLocationController;
  HomeController({required this.homeRepo, required this.appLocationController});

  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  double mainAmount = 0;
  String email = "";
  bool isLoading = true;
  String username = "";

  String serviceImagePath = "";
  String gatewayImagePath = "";
  String userImagePath = "";

  String defaultCurrency = "";
  String defaultCurrencySymbol = "";
  String currentAddress = "${MyStrings.loading.tr}...";
  int passenger = 1;
  Position? currentPosition;
  GlobalUser user = GlobalUser(id: '-1');
  List<AppService> appServicesList = [];
  List<AppPaymentMethod> paymentMethodList = [];
  RideModel runningRide = RideModel(id: "-1");
  bool isKycVerified = true;
  bool isKycPending = false;
  bool isShuttleMode = false;

  void toggleShuttleMode(bool value) {
    if (isShuttleMode == value) return;
    isShuttleMode = value;
    update();

    if (isShuttleMode) {
      if (selectedLocations.length > 1) {
        ShuttleController shuttleController = Get.find();
        shuttleController.matchRoute(
          startLat: selectedLocations[0].latitude ?? 0.0,
          startLng: selectedLocations[0].longitude ?? 0.0,
          endLat: selectedLocations[1].latitude ?? 0.0,
          endLng: selectedLocations[1].longitude ?? 0.0,
        );
      }
    } else {
      if (selectedLocations.length > 1) {
        getRideFare();
      }
    }
  }

  void updatePassenger(bool isIncrement) {
    if (isIncrement) {
      passenger = passenger + 1;
    } else {
      passenger > 1 ? passenger-- : passenger = 1;
    }
    update();
  }

  GeneralSettingResponseModel generalSettingResponseModel = GeneralSettingResponseModel();
  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    defaultCurrency = homeRepo.apiClient.getCurrency();
    defaultCurrencySymbol = homeRepo.apiClient.getCurrency(isSymbol: true);
    username = homeRepo.apiClient.getUserName();
    email = homeRepo.apiClient.getUserEmail();
    generalSettingResponseModel = homeRepo.apiClient.getGeneralSettings();
    minimumDistance = double.tryParse(homeRepo.apiClient.getMinimumRideDistance()) ?? 0.0;
    fetchLocation();
    await loadData(shouldLoad: shouldLoad);
    if (selectedLocations.length > 1) {
      await getRideFare();
    }
    isLoading = false;
    update();
  }

  // Start location permission check but don't await yet
  Future<void> fetchLocation() async {
    bool hasPermission = await MyUtils.checkAppLocationPermission(onsuccess: () {
      initialData();
    });
    printX(hasPermission);
    if (hasPermission) {
      currentPosition = await appLocationController.getCurrentPosition();
      currentAddress = appLocationController.currentAddress;
      if (selectedLocations.length != 2) {
        SelectedLocationInfo location = SelectedLocationInfo(
          address: currentAddress,
          fullAddress: currentAddress,
          latitude: appLocationController.currentPosition.latitude,
          longitude: appLocationController.currentPosition.longitude,
        );
        addLocationAtIndex(location, 0);
      }
      update(); // Ensure UI reflects added location
    }
  }

  Future<void> loadData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    update();
    try {
      ResponseModel responseModel = await homeRepo.getData();
      if (responseModel.statusCode == 200) {
        printX(responseModel.responseJson);
        DashBoardResponseModel model = DashBoardResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success && model.data != null) {
          appServicesList = model.data?.services ?? [];
          if (appServicesList.isNotEmpty && selectedService.id == '-99') {
            try {
              selectService(appServicesList[0]);
            } catch (e) {
              printX(e);
            }
          }
          paymentMethodList = model.data?.paymentMethod ?? [];
          paymentMethodList.insertAll(0, MyUtils.getDefaultPaymentMethod());
          user = model.data?.userInfo ?? GlobalUser(id: '-1');
          serviceImagePath = model.data?.serviceImagePath ?? '';
          gatewayImagePath = model.data?.gatewayImagePath ?? '';
          userImagePath = model.data?.userImagePath ?? '';
          printX(
            "RunningRideService.instance.isRunningShow ${RunningRideService.instance.isRunningShow}",
          );
          if (model.data?.runningRide != null && RunningRideService.instance.isRunningShow == false) {
            RunningRideService.instance.setIsRunning(true);
            runningRide = model.data!.runningRide!;
            
            // Only show "reached destination" message for ended rides, not running ones
            String dialogTitle = MyStrings.runningRideAlertTitle.tr;
            String dialogDescription = '';
            
            // Debug: Log the status for troubleshooting
            printX('Running ride status: ${runningRide.status}, RIDE_RUNNING: ${AppStatus.RIDE_RUNNING}, RIDE_PAYMENT_REQUESTED: ${AppStatus.RIDE_PAYMENT_REQUESTED}');
            
            if (runningRide.status == AppStatus.RIDE_PAYMENT_REQUESTED) {
              // Ride has ended, show destination reached message
              dialogDescription = MyStrings.runningRideAlertSubTitle;
            } else if (runningRide.status == AppStatus.RIDE_RUNNING) {
              // Ride is in progress, show different message
              dialogTitle = "Ride in Progress";
              dialogDescription = "Your driver is on the way. Tap to view ride details.";
            } else {
              // For other statuses (ACTIVE, etc.), use default
              dialogDescription = "You have an active ride. Tap to view details.";
            }
            
            AppDialog().showRideDetailsDialog(
              Get.context!,
              title: dialogTitle,
              description: dialogDescription,
              barrierDismissible: true,
              onTap: () {
                Get.toNamed(
                  RouteHelper.rideDetailsScreen,
                  arguments: runningRide.id,
                );
              },
              onClose: () {
                Get.closeAllSnackbars();
                Get.back();
                printX(
                  "RunningRideService.instance.isRunningShow ${RunningRideService.instance.isRunningShow}",
                );
              },
            );
          }
          update();
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e.toString());
    } finally {
      isLoading = false;
      update();
    }
  }

  bool isSubmitLoading = false;
  Future<void> createRide() async {
    isSubmitLoading = true;
    update();
    try {
      ResponseModel responseModel = await homeRepo.createRide(
        data: CreateRideRequestModel(
          serviceId: selectedService.id!,
          pickUpLocation: selectedLocations[0].fullAddress ?? "",
          pickUpLatitude: selectedLocations[0].latitude.toString(),
          pickUpLongitude: selectedLocations[0].longitude.toString(),
          destinationLocation: selectedLocations[1].fullAddress ?? "",
          destinationLatitude: selectedLocations[1].latitude.toString(),
          destinationLongitude: selectedLocations[1].longitude.toString(),
          isIntercity: rideFare.rideType?.toString() ?? '',
          pickUpDateTime: DateConverter.estimatedDate(DateTime.now()),
          numberOfPassenger: passenger.toString(),
          note: noteController.text,
          offerAmount: mainAmount.toString(),
          paymentType: selectedPaymentMethod.id == "-9" ? "2" : '1',
          gatewayCurrencyId: selectedPaymentMethod.id!,
        ),
      );
      if (responseModel.statusCode == 200) {
        CreateRideResponseModel model = CreateRideResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success) {
          printX(model.remark);
          clearData();
          if (Get.currentRoute != RouteHelper.rideDetailsScreen) {
            Get.toNamed(
              RouteHelper.rideDetailsScreen,
              arguments: model.data?.ride?.id,
            );
          }
        } else {
          printD(model.toJson());
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    } finally {
      isSubmitLoading = false;
      update();
    }
  }

  RideFareModel rideFare = RideFareModel();
  Future<void> getRideFare() async {
    try {
      if (isShuttleMode) return;
      
      if (selectedService.id == '-99') {
        return;
      }
      isPriceLocked = true;
      update();
      ResponseModel responseModel = await homeRepo.getRideFare(
        data: CreateRideRequestModel(
          serviceId: selectedService.id.toString(),
          pickUpLocation: selectedLocations[0].city.toString(),
          pickUpLatitude: selectedLocations[0].latitude.toString(),
          pickUpLongitude: selectedLocations[0].longitude.toString(),
          destinationLocation: selectedLocations[1].city.toString(),
          destinationLatitude: selectedLocations[1].latitude.toString(),
          destinationLongitude: selectedLocations[1].longitude.toString(),
          isIntercity: '1',
          pickUpDateTime: '',
          numberOfPassenger: '',
          note: '',
          offerAmount: '',
          paymentType: '',
          gatewayCurrencyId: '',
        ),
      );
      if (responseModel.statusCode == 200) {
        RideFareResponseModel model = RideFareResponseModel.fromJson((responseModel.responseJson));
        if (model.status == MyStrings.success) {
          rideFare = model.data ?? RideFareModel();
          appServicesList = model.data?.services ?? [];
          isPriceLocked = false;
          if (selectedService.id != "-99") {
            try {
              selectService(appServicesList.firstWhere((v) => v.id == selectedService.id));
            } catch (e) {
              printE(e);
            }
          }
          distance = double.tryParse(rideFare.distance.toString()) ?? 0.0;
          if (distance < minimumDistance) {
            distanceAlert();
          } else {
            isLocationShake = true;
          }
        } else {
          rideFare = RideFareModel();
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        isPriceLocked = true;
        rideFare = RideFareModel();
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printX(e);
    }
    update();
  }

  //Handle Ride Functionality Start From here
  TextEditingController pickUpLocation = TextEditingController();
  SelectedLocationInfo? pickUpLocationInfo;
  TextEditingController pickUpDestination = TextEditingController();
  SelectedLocationInfo? pickUpDestinationInfo;

  List<SelectedLocationInfo> selectedLocations = [];
  bool isServiceShake = false;
  bool isLocationShake = false;
  void updateIsServiceShake(bool value) {
    isServiceShake = value;
    update();
  }

  Future<void> addLocationAtIndex(
    SelectedLocationInfo selectedLocationInfo,
    int index, {
    bool getFareData = false,
  }) async {
    SelectedLocationInfo newLocation = selectedLocationInfo;
    if (selectedLocations.length > index && index >= 0) {
      selectedLocations[index] = newLocation;
    } else {
      selectedLocations.add(newLocation);
    }
    update();

    if (selectedLocations.length >= 2 && selectedService.id != "-99" && getFareData == true) {
      getRideFare();
    }
  }

  SelectedLocationInfo? getSelectedLocationInfoAtIndex(int index) {
    if (index >= 0 && index < selectedLocations.length) {
      return selectedLocations[index];
    } else {
      return null;
    }
  }

  double distance = -1;
  double minimumDistance = -1;

  //Handle Ride Functionality Start From here END
  void updateMainAmount(double amount) {
    mainAmount = amount;
    amountController.text = StringConverter.formatNumber(mainAmount.toString());

    update();
  }

  AppPaymentMethod selectedPaymentMethod = MyUtils.getDefaultPaymentMethod()[0];
  void selectPaymentMethod(AppPaymentMethod method) {
    printX(method.id);
    selectedPaymentMethod = method;
    update();
    Get.back();
  }

  AppService selectedService = AppService(id: '-99');

  bool isPriceLocked = false;
  Future<void> selectService(AppService service, {bool shouldLoadFare = false}) async {
    try {
      update();
      if (selectedLocations.length > 1) {
        selectedService = service;
        update();
        if (shouldLoadFare) {
          await getRideFare();
        }
        mainAmount = StringConverter.formatDouble(service.recommendAmount.toString());
        amountController.text = StringConverter.formatDouble(service.recommendAmount.toString()).toString();
      } else {
        CustomSnackBar.error(
          errorList: [MyStrings.pleaseSelectPickupAndDestination],
        );
      }
    } catch (e) {
      printE(e);
    }
  }

  // ride alert methods
  void distanceAlert() {
    CustomBottomSheet(
      child: RideDistanceWarningBottomSheetBody(
        distance: minimumDistance.toString(),
        yes: () {
          Get.back();
        },
      ),
    ).customBottomSheet(Get.context!);
  }

  bool isValidForNewRide() {
    if (selectedLocations.isEmpty || selectedLocations.length < 2) {
      CustomSnackBar.error(errorList: [MyStrings.selectDestination]);
      return false;
    } else if (selectedService.id == "-99") {
      CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
      return false;
    }
    return true;
  }

  void clearData() {
    mainAmount = 0;
    rideFare = RideFareModel();
    selectedService = AppService(id: '-99');
    amountController.text = '';
    noteController.text = '';
    passenger = 1;
    isServiceShake = false;
    isLocationShake = false;
    update();
  }
}
