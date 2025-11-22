import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';

import 'package:ovorideuser/presentation/components/shimmer/my_shimmer.dart';

class RideServiceShimmer extends StatelessWidget {
  const RideServiceShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (index) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 15),
          child: Column(
            children: [
              Row(
                children: [
                  MyShimmerWidget(
                    child: Container(
                      height: 60,
                      width: 60,
                      margin: const EdgeInsets.only(right: Dimensions.space10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          Dimensions.mediumRadius,
                        ),
                        color: MyColor.colorGrey.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Dimensions.space5),
                        MyShimmerWidget(
                          child: Container(
                            height: 20,
                            width: double.infinity,
                            margin: const EdgeInsets.only(right: Dimensions.space10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: MyColor.colorGrey.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.space5),
                        MyShimmerWidget(
                          child: Container(
                            height: 10,
                            width: 100,
                            margin: const EdgeInsets.only(right: Dimensions.space10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: MyColor.colorGrey.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
