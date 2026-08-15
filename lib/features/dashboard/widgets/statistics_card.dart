import 'package:flutter/material.dart';
import 'package:structflow/core/theme/app_colors.dart';

class StatisticsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double change;
  final bool isPositive;

  const StatisticsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
  });

  @override
  State<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends State<StatisticsCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          hovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),

        // Flutter 3.44+
        transform: Matrix4.identity()
          ..translateByDouble(
            0.0,
            hovering ? -6.0 : 0.0,
            0.0,
            1.0,
          ),

        padding: const EdgeInsets.all(22),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: hovering
                  ? widget.color.withValues(alpha: .25)
                  : Colors.black12,
              blurRadius: hovering ? 28 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(
                      alpha: .12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                ),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            Row(
              children: [
                Icon(
                  widget.isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: widget.isPositive
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),

                const SizedBox(width: 6),

                Text(
                  '${widget.change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: widget.isPositive
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 8),

                const Text(
                  'this month',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.color.withValues(
                  alpha: .08,
                ),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _bar(16),
                  _bar(24),
                  _bar(20),
                  _bar(34),
                  _bar(28),
                  _bar(42),
                  _bar(36),
                  _bar(48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double height) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 8,
      height: hovering ? height + 6 : height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius:
            BorderRadius.circular(30),
      ),
    );
  }
}