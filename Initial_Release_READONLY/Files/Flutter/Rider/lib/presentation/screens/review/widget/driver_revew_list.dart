import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/date_converter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/review/review_controller.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/components/shimmer/transaction_card_shimmer.dart';

class DriverReviewList extends StatelessWidget {
  const DriverReviewList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReviewController>(
      builder: (controller) {
        return controller.isLoading
            ? ListView.builder(
                itemBuilder: (context, index) {
                  return TransactionCardShimmer();
                },
              )
            : (controller.reviews.isEmpty && controller.isLoading == false)
                ? NoDataWidget(
                    margin: 8,
                  )
                : ListView.separated(
                    separatorBuilder: (context, index) => Container(
                      color: MyColor.borderColor.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    itemCount: controller.reviews.length,
                    itemBuilder: (context, index) {
                      final review = controller.reviews[index];

                      return Container(
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
                        margin: EdgeInsets.only(bottom: Dimensions.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyImageWidget(
                                  imageUrl: '${controller.userImagePath}/${review.ride?.user?.image}',
                                  height: Dimensions.space50,
                                  width: Dimensions.space50,
                                  radius: Dimensions.radiusHuge,
                                  isProfile: true,
                                ),
                                SizedBox(
                                  width: Dimensions.space10,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (review.ride?.user?.getFullName() ?? '').toCapitalized(),
                                              style: boldMediumLarge.copyWith(color: MyColor.getHeadingTextColor(), fontSize: Dimensions.fontTitleLarge),
                                            ),
                                          ),
                                          spaceSide(Dimensions.space10),
                                          Text(
                                            DateConverter.estimatedDate(DateTime.tryParse('${review.createdAt}') ?? DateTime.now(), formatType: DateFormatType.onlyDate),
                                            style: boldLarge.copyWith(
                                              color: MyColor.getBodyTextColor(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: Dimensions.space5),
                                      RatingBar.builder(
                                        initialRating: StringConverter.formatDouble(
                                          review.rating ?? '0',
                                        ),
                                        minRating: 1,
                                        direction: Axis.horizontal,
                                        allowHalfRating: false,
                                        itemCount: 5,
                                        itemPadding: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                        ),
                                        itemSize: Dimensions.fontExtraLarge,
                                        itemBuilder: (context, _) => const Icon(
                                          Icons.star_rate_rounded,
                                          color: MyColor.colorOrange,
                                        ),
                                        ignoreGestures: true,
                                        onRatingUpdate: (v) {},
                                      ),
                                      SizedBox(
                                        height: Dimensions.space5,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            spaceDown(Dimensions.space10),
                            InnerShadowContainer(
                              width: double.infinity,
                              backgroundColor: MyColor.neutral50,
                              borderRadius: Dimensions.largeRadius,
                              blur: 6,
                              offset: Offset(3, 3),
                              shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                              isShadowTopLeft: true,
                              isShadowBottomRight: true,
                              padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  review.review ?? '',
                                  style: lightDefault.copyWith(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
      },
    );
  }
}
