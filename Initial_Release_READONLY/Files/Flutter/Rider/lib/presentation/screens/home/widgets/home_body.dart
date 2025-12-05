import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/screens/home/section/ride_create_form.dart';
import 'package:ovorideuser/presentation/screens/home/section/ride_service_section.dart';
import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/utils/util.dart';
import '../../../components/divider/custom_spacer.dart';

class HomeBody extends StatefulWidget {
  final HomeController controller;
  const HomeBody({super.key, required this.controller});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //SERVICES
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.controller.isLoading == false && widget.controller.appServicesList.isEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: MyColor.getCardBgColor(),
                  boxShadow: MyUtils.getCardShadow(),
                  borderRadius: BorderRadius.circular(Dimensions.moreRadius),
                ),
                width: double.infinity,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: Dimensions.space16, vertical: Dimensions.space16),
                child: Center(
                  child: Text(
                    MyStrings.noServiceAvailable.tr,
                    style: regularDefault.copyWith(
                      color: MyColor.bodyTextColor,
                    ),
                  ),
                ),
              ),
            ] else ...[
              RideServiceSection(),
            ],
          ],
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RideCreateForm(),
              spaceDown(Dimensions.space15),
            ],
          ),
        ),
        spaceDown(Dimensions.space50 + 20),
      ],
    );
  }
}
