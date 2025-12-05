import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/faq/faq_controller.dart';
import 'package:ovorideuser/data/repo/faq/faq_repo.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/components/shimmer/faq_shimmer.dart';
import 'package:ovorideuser/presentation/screens/faq/widget/faq_widget.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  late FaqController controller;

  @override
  void initState() {
    super.initState();

    // Initialize repo and controller
    Get.put(FaqRepo(apiClient: Get.find()));
    controller = Get.put(FaqController(faqRepo: Get.find()));

    // Fetch FAQ data after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getFaqList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FaqController>(builder: (controller) {
      return AnnotatedRegionWidget(
        child: Scaffold(
          backgroundColor: MyColor.secondaryScreenBgColor,
          appBar: CustomAppBar(
            title: MyStrings.faq,
            isTitleCenter: false,
            elevation: 0.01,
          ),
          body: controller.isLoading
              ? ListView.separated(
                  itemCount: 10,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(Dimensions.space16),
                  separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space10),
                  itemBuilder: (_, __) => const FaqCardShimmer(),
                )
              : controller.faqList.isEmpty
                  ? const NoDataWidget(fromRide: true)
                  : ListView.separated(
                      itemCount: controller.faqList.length,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(Dimensions.space16),
                      separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space10),
                      itemBuilder: (context, index) {
                        final faq = controller.faqList[index].dataValues;
                        return FaqListItem(
                          press: () => controller.changeSelectedIndex(index),
                          selectedIndex: controller.selectedIndex,
                          index: index,
                          question: faq?.question ?? "",
                          answer: faq?.answer ?? "",
                        );
                      },
                    ),
        ),
      );
    });
  }
}
