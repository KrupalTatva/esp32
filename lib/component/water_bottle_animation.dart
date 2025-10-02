import 'package:esp/component/Color.dart';
import 'package:flutter/material.dart';

class WaterBottleAnimation extends StatelessWidget {
  final double fillPercent;
  final double waterAmount;

  const WaterBottleAnimation({
    Key? key,
    required this.fillPercent,
    required this.waterAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Water bottle
        Expanded(
          child: Container(
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
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
                            AppColors.primary,
                            AppColors.onPrimary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),

                // Water drop icon at top
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Icon(
                    Icons.water_drop,
                    color: AppColors.primary44,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Water amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${waterAmount.toStringAsFixed(1)} L',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}