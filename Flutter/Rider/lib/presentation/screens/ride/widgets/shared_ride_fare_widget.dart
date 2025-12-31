import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import 'package:ovorideuser/presentation/components/text/small_text.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';

class SharedRideFareWidget extends StatefulWidget {
  final RideModel ride;
  final RideDetailsController rideDetailsController;
  
  const SharedRideFareWidget({
    super.key,
    required this.ride,
    required this.rideDetailsController,
  });

  @override
  State<SharedRideFareWidget> createState() => _SharedRideFareWidgetState();
}

class _SharedRideFareWidgetState extends State<SharedRideFareWidget> {
  File? _selectedImage;
  final TextEditingController _fareAmountController = TextEditingController();
  bool _isUploading = false;
  bool _canUpload = false;
  bool _isRider1 = false;

  @override
  void initState() {
    super.initState();
    _checkUploadPermission();
    if (widget.ride.fareAmountText != null) {
      _fareAmountController.text = widget.ride.fareAmountText!;
    }
  }

  void _checkUploadPermission() {
    final currentUserId = widget.rideDetailsController.repo.apiClient.getUserID();
    _isRider1 = widget.ride.userId == currentUserId;
    
    // Check if user can upload (must have first pickup in sequence)
    final noScreenshot = widget.ride.fareScreenshot == null || widget.ride.fareScreenshot!.isEmpty;
    final hasSecondUser = widget.ride.secondUser != null;
    
    if (hasSecondUser && noScreenshot && widget.ride.sharedRideSequence != null && widget.ride.sharedRideSequence!.isNotEmpty) {
      final firstPickup = widget.ride.sharedRideSequence![0];
      _canUpload = (firstPickup == 'S1' && _isRider1) || (firstPickup == 'S2' && !_isRider1);
    } else {
      _canUpload = _isRider1 && hasSecondUser && noScreenshot; // Fallback
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      CustomSnackBar.error(errorList: ['Failed to pick image: $e']);
    }
  }

  Future<void> _uploadFareScreenshot() async {
    if (_selectedImage == null) {
      CustomSnackBar.error(errorList: ['Please select an image']);
      return;
    }

    final fareAmount = double.tryParse(_fareAmountController.text);
    if (fareAmount == null || fareAmount <= 0) {
      CustomSnackBar.error(errorList: ['Please enter a valid fare amount']);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final sharedRideController = Get.find<SharedRideController>();
      final response = await sharedRideController.sharedRideRepo.uploadFareScreenshot(
        rideId: widget.ride.id ?? '',
        fareAmount: fareAmount.toString(),
        fareImage: _selectedImage!,
      );

      if (response.statusCode == 200) {
        final responseData = response.responseJson;
        if (responseData['success'] == true) {
          CustomSnackBar.success(successList: [responseData['message'] ?? 'Fare screenshot uploaded successfully']);
          
          // Refresh ride details
          await widget.rideDetailsController.getRideDetails(widget.ride.id ?? '', shouldLoading: false);
          
          setState(() {
            _selectedImage = null;
            _fareAmountController.clear();
            _canUpload = false;
          });
        } else {
          CustomSnackBar.error(errorList: [responseData['message'] ?? 'Failed to upload']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      CustomSnackBar.error(errorList: ['Error: $e']);
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _viewFullImage(String imageUrl) {
    Get.toNamed(RouteHelper.previewImageScreen, arguments: imageUrl);
  }

  @override
  void dispose() {
    _fareAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFareScreenshot = widget.ride.fareScreenshot != null && widget.ride.fareScreenshot!.isNotEmpty;
    // Get ride image path from controller (stored when ride details are loaded)
    final rideImagePath = widget.rideDetailsController.rideImagePath;
    final imagePath = hasFareScreenshot && rideImagePath.isNotEmpty
        ? '${UrlContainer.domainUrl}/$rideImagePath/${widget.ride.fareScreenshot}'
        : null;
    
    final rider1Fare = widget.ride.rider1Fare != null ? double.tryParse(widget.ride.rider1Fare!) : null;
    final rider2Fare = widget.ride.rider2Fare != null ? double.tryParse(widget.ride.rider2Fare!) : null;
    final currencySym = widget.rideDetailsController.currencySym;

    return Container(
      padding: EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: MyColor.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderText(
            text: 'Fare Information',
            style: boldLarge.copyWith(color: MyColor.getHeadingTextColor()),
          ),
          spaceDown(Dimensions.space15),
          
          // Show uploaded fare screenshot if available
          if (hasFareScreenshot && imagePath != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmallText(
                        text: 'Fare Screenshot',
                        textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                      ),
                      spaceDown(Dimensions.space5),
                      GestureDetector(
                        onTap: () => _viewFullImage(imagePath),
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            border: Border.all(color: MyColor.neutral300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            child: imagePath != null
                                ? MyImageWidget(
                                    imageUrl: imagePath,
                                    height: 80,
                                    width: 80,
                                    boxFit: BoxFit.cover,
                                  )
                                : SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.ride.fareAmountText != null) ...[
                  SizedBox(width: Dimensions.space15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmallText(
                          text: 'Total Fare',
                          textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                        spaceDown(Dimensions.space5),
                        HeaderText(
                          text: '${currencySym}${widget.ride.fareAmountText}',
                          style: boldLarge.copyWith(color: MyColor.getPrimaryColor()),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            spaceDown(Dimensions.space15),
            
            // Show calculated fares for both users
            if (rider1Fare != null && rider2Fare != null) ...[
              Divider(),
              spaceDown(Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SmallText(
                          text: 'Rider 1 Fare',
                          textStyle: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                        spaceDown(Dimensions.space5),
                        HeaderText(
                          text: '${currencySym}${rider1Fare.toStringAsFixed(2)}',
                          style: boldMediumLarge.copyWith(
                            color: _isRider1 ? MyColor.getPrimaryColor() : MyColor.getHeadingTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: MyColor.neutral300,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SmallText(
                          text: 'Rider 2 Fare',
                          textStyle: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                        spaceDown(Dimensions.space5),
                        HeaderText(
                          text: '${currencySym}${rider2Fare.toStringAsFixed(2)}',
                          style: boldMediumLarge.copyWith(
                            color: !_isRider1 ? MyColor.getPrimaryColor() : MyColor.getHeadingTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ] else if (_canUpload) ...[
            // Upload section for user with first pickup
            SmallText(
              text: 'Upload fare screenshot (You have the first pickup)',
              textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
            ),
            spaceDown(Dimensions.space10),
            
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: MyColor.neutral50,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: MyColor.neutral300),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40, color: MyColor.getPrimaryColor()),
                          spaceDown(Dimensions.space5),
                          SmallText(
                            text: 'Tap to select image',
                            textStyle: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                          ),
                        ],
                      ),
              ),
            ),
            spaceDown(Dimensions.space10),
            
            // Fare amount input
            TextField(
              controller: _fareAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Fare Amount',
                hintText: 'Enter total fare amount',
                prefixText: currencySym,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                ),
              ),
            ),
            spaceDown(Dimensions.space15),
            
            // Upload button
            RoundedButton(
              text: 'Upload Fare Screenshot',
              press: _uploadFareScreenshot,
              isLoading: _isUploading,
            ),
          ] else ...[
            SmallText(
              text: 'Waiting for fare screenshot upload...',
              textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
            ),
          ],
        ],
      ),
    );
  }
}

