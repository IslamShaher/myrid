import 'package:flutter/material.dart';
import 'package:ovorideuser/core/helper/date_converter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';

import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../data/controller/payment_history/payment_history_controller.dart';
import '../../../components/animated_widget/expanded_widget.dart';
import '../../../components/column_widget/card_column.dart';

class CustomPaymentCard extends StatelessWidget {
  final int index;
  final int expandIndex;

  const CustomPaymentCard({
    super.key,
    required this.index,
    required this.expandIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentHistoryController>(
      builder: (controller) {
        final payment = controller.transactionList[index];

        return GestureDetector(
          onTap: () {
            controller.changeExpandIndex(index);
          },
          child: Container(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${controller.currencySym}${StringConverter.formatNumber(payment.amount.toString())}",
                          style: boldExtraLarge.copyWith(
                            color: MyColor.getHeadingTextColor(),
                          ),
                        ),
                        spaceDown(Dimensions.space15),
                        Text(
                          payment.ride?.uid ?? '',
                          style: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.space5,
                            vertical: Dimensions.space2,
                          ),
                          decoration: BoxDecoration(
                            color: MyUtils.paymentStatusColor(payment.paymentType ?? '1').withValues(alpha: 0.01),
                            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                            border: Border.all(
                              color: MyUtils.paymentStatusColor(payment.paymentType ?? '0'),
                            ),
                          ),
                          child: Text(
                            MyUtils.paymentStatus(payment.paymentType ?? '1'),
                            style: boldDefault.copyWith(
                              fontSize: 16,
                              color: MyUtils.paymentStatusColor(
                                payment.paymentType ?? '0',
                              ),
                            ),
                          ),
                        ),
                        spaceDown(Dimensions.space15),
                        Text(
                          DateConverter.estimatedDate(
                            DateTime.tryParse('${payment.createdAt}') ?? DateTime.now(),
                          ),
                          style: regularSmall.copyWith(
                            color: MyColor.getBodyTextColor(),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ExpandedSection(
                  expand: controller.expandIndex == index,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomDivider(space: Dimensions.space15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardColumn(
                            header: MyStrings.pickUpLocation,
                            body: payment.ride?.pickupLocation ?? "",
                            bodyMaxLine: 5,
                            space: Dimensions.space10,
                            headerTextStyle: regularDefault,
                            bodyTextStyle: regularSmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: MyColor.getTextColor().withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          spaceDown(Dimensions.space10),
                          CardColumn(
                            alignmentEnd: false,
                            header: MyStrings.destination,
                            body: payment.ride?.destination ?? "",
                            bodyMaxLine: 5,
                            space: Dimensions.space8,
                            headerTextStyle: regularDefault,
                            bodyTextStyle: regularSmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: MyColor.getTextColor().withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.space10),
                      Row(
                        children: [
                          Expanded(
                            child: CardColumn(
                              header: MyStrings.distance,
                              body: '${payment.ride?.getDistance()} ${MyUtils.getDistanceLabel(distance: payment.ride?.distance, unit: Get.find<ApiClient>().getDistanceUnit())}',
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CardColumn(
                              alignmentEnd: true,
                              header: MyStrings.duration,
                              body: payment.ride?.duration ?? '',
                              headerTextStyle: regularDefault,
                              bodyTextStyle: regularSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: MyColor.getTextColor().withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
