import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';

class LocationPickTextField extends StatefulWidget {
  final String? labelText;
  final String? hintText;
  final Function? onChanged;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  final VoidCallback? onTap;
  final TextInputAction inputAction;
  final Color fillColor;
  final Color borderColor;
  final Color? shadowColor;
  final Color textColor;
  final VoidCallback? onSubmit;
  final double? radius;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const LocationPickTextField({
    super.key,
    this.labelText,
    this.fillColor = MyColor.transparentColor,
    this.borderColor = MyColor.borderColor,
    this.shadowColor,
    this.textColor = MyColor.bodyTextColor,
    required this.onChanged,
    this.hintText,
    this.controller,
    this.textInputType,
    this.onTap,
    this.inputAction = TextInputAction.next,
    this.onSubmit,
    this.radius = Dimensions.mediumRadius,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  State<LocationPickTextField> createState() => _LocationPickTextFieldState();
}

class _LocationPickTextFieldState extends State<LocationPickTextField> {
  @override
  Widget build(BuildContext context) {
    return InnerShadowContainer(
      width: double.infinity,
      backgroundColor: widget.fillColor,
      borderRadius: Dimensions.moreRadius,
      blur: 6,
      offset: Offset(3, 3),
      shadowColor: widget.shadowColor ?? MyColor.colorBlack.withValues(alpha: 0.04),
      isShadowTopLeft: true,
      isShadowBottomRight: true,
      child: TextFormField(
        style: regularDefault.copyWith(
          color: widget.textColor,
          fontSize: Dimensions.fontLarge,
        ),
        readOnly: widget.readOnly,
        cursorColor: widget.textColor,
        controller: widget.controller,
        autofocus: false,
        textInputAction: widget.inputAction,
        keyboardType: widget.textInputType,
        decoration: InputDecoration(
          hintStyle: regularDefault.copyWith(
            color: widget.textColor,
            fontSize: Dimensions.fontLarge,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 15,
          ),
          fillColor: MyColor.transparentColor,
          filled: true,
          hintText: widget.hintText?.tr ?? '',
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
          prefixIconConstraints: BoxConstraints.loose(Size(40, 40)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (text) => widget.onChanged!(text),
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          }
        },
      ),
    );
  }
}
