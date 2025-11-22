import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';

import 'package:ovorideuser/presentation/components/shimmer/my_shimmer.dart';

class CreateRideShimmer extends StatelessWidget {
  const CreateRideShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.mediumRadius,
                      ),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.mediumRadius,
                      ),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space20),
          Row(
            children: [
              Expanded(
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.mediumRadius,
                      ),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        Dimensions.mediumRadius,
                      ),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                flex: 1,
                child: MyShimmerWidget(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: MyColor.colorGrey.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
