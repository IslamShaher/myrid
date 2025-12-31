import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/bottom_sheet_header_row.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';
import 'package:ovorideuser/core/utils/url_container.dart';

class SharedRideRateUserWidget extends StatefulWidget {
  final RideModel ride;
  final RideDetailsController rideDetailsController;
  
  const SharedRideRateUserWidget({
    super.key,
    required this.ride,
    required this.rideDetailsController,
  });

  @override
  State<SharedRideRateUserWidget> createState() => _SharedRideRateUserWidgetState();
}

class _SharedRideRateUserWidgetState extends State<SharedRideRateUserWidget> {
  double _rating = 0.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0.0) {
      CustomSnackBar.error(errorList: ['Please select a rating']);
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      CustomSnackBar.error(errorList: ['Please write a review']);
      return;
    }

    await widget.rideDetailsController.rateOtherUserInSharedRide(
      _rating.toInt(),
      _reviewController.text.trim(),
    );

    // Close bottom sheet after successful rating
    if (widget.rideDetailsController.isRatingOtherUser == false) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.rideDetailsController.repo.apiClient.getUserID();
    final isRider1 = widget.ride.userId == currentUserId;
    final otherUser = isRider1 ? widget.ride.secondUser : widget.ride.user;
    // Use a default path or get from API - for now use same pattern as driver
    final userImagePath = 'user'; // This should come from API response, using default for now

    return GetBuilder<RideDetailsController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHeaderRow(),
            spaceDown(Dimensions.space10),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Rate Your Co-Rider',
                style: regularDefault.copyWith(
                  fontSize: Dimensions.fontOverLarge - 1,
                ),
              ),
            ),
            spaceDown(Dimensions.space20),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: MyColor.colorWhite,
                      border: Border.all(color: MyColor.borderColor),
                      shape: BoxShape.circle,
                    ),
                    child: MyImageWidget(
                      imageUrl: otherUser != null && otherUser.image != null
                          ? '${UrlContainer.domainUrl}/$userImagePath/${otherUser.image}'
                          : '',
                      height: 85,
                      width: 85,
                      radius: 50,
                      isProfile: true,
                    ),
                  ),
                  spaceDown(Dimensions.space8),
                  Text(
                    otherUser != null
                        ? "${otherUser.firstname ?? ''} ${otherUser.lastname ?? ''}"
                        : 'Unknown User',
                    style: regularDefault.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            spaceDown(Dimensions.space30),
            Text(
              MyStrings.ratingDriver.tr.replaceAll('Driver', 'Co-Rider'),
              style: semiBoldDefault.copyWith(
                fontSize: Dimensions.fontOverLarge + 2,
              ),
            ),
            spaceDown(Dimensions.space20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            spaceDown(Dimensions.space25 - 1),
            Text(
              MyStrings.whatCouldBetter.tr,
              style: mediumDefault.copyWith(
                fontSize: Dimensions.fontOverLarge - 1,
              ),
            ),
            spaceDown(Dimensions.space12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space12,
              ),
              child: CustomTextField(
                onChanged: (v) {},
                controller: _reviewController,
                hintText: MyStrings.reviewMsgHintText.tr,
                maxLines: 5,
              ),
            ),
            spaceDown(Dimensions.space30 + 2),
            RoundedButton(
              text: MyStrings.submit,
              textColor: MyColor.colorWhite,
              isLoading: controller.isRatingOtherUser,
              press: _submitRating,
            ),
          ],
        );
      },
    );
  }
}

