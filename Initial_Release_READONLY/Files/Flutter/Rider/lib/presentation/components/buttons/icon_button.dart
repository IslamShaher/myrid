import 'package:flutter_svg/flutter_svg.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:flutter/material.dart';

import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';

class CustomIconButton extends StatelessWidget {
  final String? name;
  final String icon;
  Color? textColor;
  Color? iconColor;
  Color? bgColor;
  TextStyle? style;
  double? iconSize;
  bool? isSvg = false;
  bool isOutline;
  final VoidCallback press;

  CustomIconButton({
    super.key,
    this.name,
    required this.icon,
    required this.press,
    this.textColor,
    this.iconColor,
    this.bgColor,
    this.style,
    this.iconSize = 32,
    this.isSvg = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: press,
      child: InnerShadowContainer(
        width: double.infinity,
        backgroundColor: name != null ? MyColor.colorWhite : MyColor.getPrimaryColor().withValues(alpha: 0.15),
        borderRadius: Dimensions.largeRadius,
        blur: 6,
        offset: Offset(3, 3),
        shadowColor: name != null ? MyColor.colorBlack.withValues(alpha: 0.04) : MyColor.getPrimaryColor().withValues(alpha: 0.04),
        isShadowTopLeft: true,
        isShadowBottomRight: true,
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.space20,
          vertical: Dimensions.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSvg!
                ? SvgPicture.asset(
                    icon,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      iconColor ?? MyColor.getPrimaryColor(),
                      BlendMode.srcIn,
                    ),
                    height: iconSize,
                    width: iconSize,
                  )
                : Image.asset(
                    icon,
                    height: iconSize,
                    width: iconSize,
                    color: iconColor,
                  ),
            if (name != null) ...[
              const SizedBox(width: Dimensions.space10),
              Flexible(
                child: Text(
                  (name ?? '').tr,
                  overflow: TextOverflow.ellipsis,
                  style: style ??
                      boldDefault.copyWith(
                        fontSize: Dimensions.fontTitleLarge,
                        fontWeight: FontWeight.w700,
                        color: iconColor ?? MyColor.colorWhite,
                      ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
