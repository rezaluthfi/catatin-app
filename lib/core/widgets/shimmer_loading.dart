import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Widget shimmer loading yang bergerak sebagai pengganti CircularProgressIndicator.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildShimmerCard(height: 140),
              const SizedBox(height: 20),
              _buildShimmerCard(height: 56),
              const SizedBox(height: 20),
              _buildShimmerCard(height: 72),
              const SizedBox(height: 12),
              _buildShimmerCard(height: 72),
              const SizedBox(height: 12),
              _buildShimmerCard(height: 72),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            AppColors.border,
            AppColors.surfaceVariant,
            AppColors.border,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Shimmer khusus untuk daftar list items (untuk Rekap & Piutang).
class ShimmerList extends StatefulWidget {
  const ShimmerList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  State<ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<ShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get _shimmerGradient => LinearGradient(
        begin: Alignment(_animation.value - 1, 0),
        end: Alignment(_animation.value, 0),
        colors: const [
          AppColors.border,
          AppColors.surfaceVariant,
          AppColors.border,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: _shimmerGradient,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: _shimmerGradient,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(widget.itemCount, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: _shimmerGradient,
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
