import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/ride/all_ride_controller.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/components/shimmer/ride_shimmer.dart';
import 'package:ovorideuser/presentation/screens/ride/widget/ride_info_card.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/dimensions.dart';

class AllRidesListSection extends StatelessWidget {
  const AllRidesListSection({super.key, required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AllRideController>(
      builder: (controller) {
        return RefreshIndicator(
          onRefresh: () async {
            controller.initialData(tabID: controller.selectedTab);
          },
          color: MyColor.primaryColor,
          child: controller.isLoading
              ? ListView.separated(
                  itemCount: 10,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: Dimensions.space10),
                  itemBuilder: (_, __) => const RideShimmer(),
                )
              : controller.isLoading == false && controller.rideList.isEmpty
                  ? NoDataWidget(fromRide: true, text: MyStrings.noDataToShow)
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: controller.rideList.length + 1,
                      separatorBuilder: (context, index) {
                        return SizedBox(height: Dimensions.space10);
                      },
                      itemBuilder: (context, index) {
                        if (controller.rideList.length == index) {
                          return controller.hasNext()
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: const RideShimmer(),
                                )
                              : const SizedBox();
                        }
                        return RideInfoCard(
                          controller: controller,
                          ride: controller.rideList[index],
                        );
                      },
                    ),
        );
      },
    );
  }
}
