import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/review/review_controller.dart';
import 'package:ovorideuser/data/repo/review/review_repo.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/shimmer/transaction_card_shimmer.dart';
import 'package:ovorideuser/presentation/screens/review/widget/car_information.dart';
import 'package:ovorideuser/presentation/screens/review/widget/driver_revew_list.dart';

class DriverReviewHistoryScreen extends StatefulWidget {
  final String driverId;
  const DriverReviewHistoryScreen({super.key, required this.driverId});

  @override
  State<DriverReviewHistoryScreen> createState() => _DriverReviewHistoryScreenState();
}

class _DriverReviewHistoryScreenState extends State<DriverReviewHistoryScreen> {
  bool isReviewTab = true;
  @override
  void initState() {
    Get.put(ReviewRepo(apiClient: Get.find()));
    final controller = Get.put(ReviewController(repo: Get.find()));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((t) {
      controller.getReview(widget.driverId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: GetBuilder<ReviewController>(builder: (controller) {
        return Scaffold(
          backgroundColor: MyColor.secondaryScreenBgColor,
          appBar: CustomAppBar(
            title: controller.driver?.getFullName() ?? MyStrings.driver.tr,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.space16),
            child: Column(
              children: [
                spaceDown(Dimensions.space20),
                Container(
                  decoration: BoxDecoration(
                    color: MyColor.getCardBgColor(),
                    boxShadow: MyUtils.getCardShadow(),
                    borderRadius: BorderRadius.circular(Dimensions.moreRadius),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space16,
                    vertical: Dimensions.space16,
                  ),
                  child: controller.isLoading
                      ? TransactionCardShimmer()
                      : Row(
                          children: [
                            MyImageWidget(
                              imageUrl: '${controller.driverImagePath}/${controller.driver?.avatar}',
                              height: Dimensions.space50,
                              width: Dimensions.space50,
                              radius: Dimensions.radiusHuge,
                              isProfile: true,
                            ),
                            spaceSide(Dimensions.space10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${controller.driver?.getFullName()}',
                                    style: semiBoldDefault.copyWith(
                                      color: MyColor.getHeadingTextColor(),
                                      fontSize: Dimensions.fontTitleLarge,
                                    ),
                                  ),
                                  spaceDown(Dimensions.space3),
                                  Row(
                                    children: [
                                      CustomSvgPicture(
                                        image: MyIcons.email,
                                        fit: BoxFit.contain,
                                        color: MyColor.primaryColor,
                                        height: Dimensions.fontLarge,
                                      ),
                                      spaceSide(Dimensions.space5),
                                      Expanded(
                                        child: Text(
                                          controller.driver?.email ?? "",
                                          style: regularDefault.copyWith(
                                            color: MyColor.getBodyTextColor(),
                                            fontSize: Dimensions.fontDefault,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingBar.builder(
                                  initialRating: double.tryParse(controller.driver?.avgRating ?? "0") ?? 0,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemPadding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                  ),
                                  itemSize: Dimensions.fontOverLarge,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star_rate_rounded,
                                    color: MyColor.colorOrange,
                                  ),
                                  ignoreGestures: true,
                                  onRatingUpdate: (v) {},
                                ),
                                spaceDown(Dimensions.space5),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${MyStrings.avgRating.tr} ',
                                        style: regularDefault.copyWith(color: MyColor.getBodyTextColor().withValues(alpha: 0.8), fontSize: Dimensions.fontDefault),
                                      ),
                                      TextSpan(
                                        text: ' ${(double.tryParse(controller.driver?.avgRating ?? "0") ?? 0)}'.toCapitalized(),
                                        style: boldDefault.copyWith(color: MyColor.getHeadingTextColor(), fontSize: Dimensions.fontLarge),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                ),
                spaceDown(Dimensions.space20),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isReviewTab = true;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: isReviewTab ? MyColor.primaryColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              MyStrings.reviews.tr.toUpperCase(),
                              style: boldOverLarge.copyWith(
                                color: isReviewTab ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
                              ),
                            ),
                          ),
                        ),
                        spaceSide(Dimensions.space20),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isReviewTab = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !isReviewTab ? MyColor.primaryColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              MyStrings.information.tr.toUpperCase(),
                              style: boldOverLarge.copyWith(
                                color: !isReviewTab ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                spaceDown(Dimensions.space20),
                Expanded(
                  child: isReviewTab ? DriverReviewList() : CarInformation(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
