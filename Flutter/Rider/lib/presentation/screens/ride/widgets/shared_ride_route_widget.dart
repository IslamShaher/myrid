import 'package:flutter/material.dart';
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MyColor.neutral100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MyColor.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Route Order:", style: regularSmall.copyWith(color: MyColor.bodyMutedTextColor, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          // Show all 4 points with connections
          Row(
            children: [
              Expanded(
                child: _buildPoint('S1', "Rider 1\nPickup", Colors.purple),
              ),
              _buildConnection(sequence.indexOf('S1'), sequence.indexOf('S2')),
              Expanded(
                child: _buildPoint('S2', "Your\nPickup", Colors.orange),
              ),
              _buildConnection(sequence.indexOf('S2'), sequence.indexOf('E1')),
              Expanded(
                child: _buildPoint('E1', "Rider 1\nDropoff", Colors.purple),
              ),
              _buildConnection(sequence.indexOf('E1'), sequence.indexOf('E2')),
              Expanded(
                child: _buildPoint('E2', "Your\nDropoff", Colors.orange),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Show sequence order below
          Wrap(
            spacing: 8,
            children: sequence.asMap().entries.map((entry) {
              int index = entry.key;
              String code = entry.value;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPointColor(code).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getPointColor(code)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${index + 1}. ",
                      style: regularSmall.copyWith(color: _getPointColor(code), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getPointLabel(code),
                      style: regularSmall.copyWith(color: _getPointColor(code)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPoint(String code, String label, Color color) {
    bool isInSequence = sequence.contains(code);
    int position = sequence.indexOf(code);
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isInSequence ? color : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isInSequence ? color : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: isInSequence
                ? Text(
                    "${position + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : Icon(Icons.location_off, size: 20, color: Colors.grey),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: regularSmall.copyWith(
            color: isInSequence ? color : Colors.grey,
            fontWeight: isInSequence ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildConnection(int fromIndex, int toIndex) {
    if (fromIndex == -1 || toIndex == -1 || toIndex != fromIndex + 1) {
      return SizedBox(width: 8);
    }
    
    // Determine color based on which points are connected
    String fromCode = sequence[fromIndex];
    String toCode = sequence[toIndex];
    Color connectionColor;
    
    if ((fromCode == 'S1' && toCode == 'E1') || (fromCode == 'E1' && toCode == 'S1')) {
      connectionColor = Colors.purple;
    } else if ((fromCode == 'S2' && toCode == 'E2') || (fromCode == 'E2' && toCode == 'S2')) {
      connectionColor = Colors.orange;
    } else {
      connectionColor = MyColor.getPrimaryColor();
    }
    
    return Container(
      width: 20,
      height: 2,
      color: connectionColor,
      child: Row(
        children: [
          Expanded(child: Container(color: connectionColor)),
          Icon(Icons.arrow_forward, size: 12, color: connectionColor),
        ],
      ),
    );
  }

  Color _getPointColor(String code) {
    if (code == 'S1' || code == 'E1') return Colors.purple;
    if (code == 'S2' || code == 'E2') return Colors.orange;
    return MyColor.getPrimaryColor();
  }

  String _getPointLabel(String code) {
    if (code == 'S1') return "R1 Pickup";
    if (code == 'E1') return "R1 Dropoff";
    if (code == 'S2') return "Your Pickup";
    if (code == 'E2') return "Your Dropoff";
    return code;
  }
}
