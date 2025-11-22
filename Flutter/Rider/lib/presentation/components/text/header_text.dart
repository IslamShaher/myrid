import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/style.dart';

class HeaderText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final TextStyle style;

  const HeaderText({
    super.key,
    required this.text,
    this.textAlign,
    this.style = semiBoldOverLarge,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text.tr, textAlign: textAlign, style: style);
  }
}
