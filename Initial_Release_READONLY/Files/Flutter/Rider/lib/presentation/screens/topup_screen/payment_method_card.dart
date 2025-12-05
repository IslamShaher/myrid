// ignore_for_file: unrelated_type_equality_checks

import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/data/model/global/app/app_payment_method.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/dimensions.dart';
import '../../../core/utils/my_color.dart';
import '../../../core/utils/style.dart';

// ignore: must_be_immutable
class PaymentMethodCard extends StatelessWidget {
  final VoidCallback press;
  AppPaymentMethod paymentMethod;
  final String assetPath;
  bool selected = false;
  PaymentMethodCard({
    super.key,
    required this.press,
    required this.paymentMethod,
    required this.assetPath,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 10),
      child: InnerShadowContainer(
        width: double.infinity,
        backgroundColor: MyColor.neutral50,
        borderRadius: Dimensions.largeRadius,
        blur: 6,
        offset: Offset(3, 3),
        shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
        isShadowTopLeft: true,
        isShadowBottomRight: true,
        padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space2, horizontal: Dimensions.space2),
        child: CheckboxListTile(
          value: selected,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.space10),
          ),
          onChanged: (val) {
            press();
          },
          contentPadding: const EdgeInsetsDirectional.only(
            start: Dimensions.space20,
            end: Dimensions.space20,
            top: Dimensions.space1,
            bottom: Dimensions.space1,
          ),
          activeColor: MyColor.primaryColor,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (paymentMethod.id == "-9" || paymentMethod.id == "-99") ...[
                // Image.asset(
                //   paymentMethod.method?.image ?? '',
                //   width: Dimensions.space40,
                //   height: Dimensions.space40,
                // ),
                CustomSvgPicture(
                  image: MyIcons.money,
                  color: MyColor.primaryColor,
                  width: Dimensions.space30,
                  height: Dimensions.space30,
                ),
              ] else ...[
                MyImageWidget(
                  imageUrl: '$assetPath/${paymentMethod.method?.image}',
                  width: Dimensions.space40,
                  height: Dimensions.space40,
                  boxFit: BoxFit.fitWidth,
                  radius: 4,
                ),
              ],
              spaceSide(Dimensions.space10),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  paymentMethod.name ?? '',
                  style: semiBoldDefault.copyWith(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
