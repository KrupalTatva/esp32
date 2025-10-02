import 'package:esp/component/Color.dart';
import 'package:flutter/material.dart';

class WaterFillAnimation extends StatelessWidget {
  final double fillPercent;
  final double waterAmount;

  const WaterFillAnimation({
    Key? key,
    required this.fillPercent,
    required this.waterAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Water fill
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fillPercent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary44,
                      AppColors.onPrimary44,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Water amount text
          /*Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${waterAmount.toStringAsFixed(1)}L',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),*/
        ],
      ),
    );
  }
}