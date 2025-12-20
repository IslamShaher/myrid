import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';

class SharedRideRouteWidget extends StatelessWidget {
  final List<String> sequence;
  
  const SharedRideRouteWidget({super.key, required this.sequence});

  @override
  Widget build(BuildContext context) {
    if (sequence.isEmpty) return const SizedBox.shrink();

    // Mapping code to human readable
    // S1 = Rider 1 Pickup
    // E1 = Rider 1 Drop
    // S2 = You Pickup (Searching User)
    // E2 = You Drop (Searching User)

    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Route Order:", style: regularSmall.copyWith(color: MyColor.bodyMutedTextColor)),
          SizedBox(height: 8),
          Row(
            children: sequence.map((code) {
               return Expanded(
                 child: Row(
                   children: [
                     // Dot/Label
                     Expanded(child: _buildPoint(code)),
                     // Arrow (if not last)
                     if (code != sequence.last)
                       Icon(Icons.arrow_right_alt, color: Colors.grey, size: 16),
                   ],
                 ),
               );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(String code) {
    bool isMe = code.contains('2'); // S2 or E2
    String label = "";
    if (code == 'S1') label = "R1 Pick";
    if (code == 'E1') label = "R1 Drop";
    if (code == 'S2') label = "You Pick";
    if (code == 'E2') label = "You Drop";

    Color color = isMe ? MyColor.primaryColor : MyColor.bodyMutedTextColor;
    FontWeight weight = isMe ? FontWeight.bold : FontWeight.normal;

    return Column(
      children: [
        CircleAvatar(
          radius: 6,
          backgroundColor: color,
        ),
        SizedBox(height: 4),
        Text(
          label, 
          style: regularSmall.copyWith(color: color, fontSize: 10, fontWeight: weight),
          textAlign: TextAlign.center,
          maxLines: 2,
        )
      ],
    );
  }
}
