import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum ShimmerType { dashboard, recap }

/// Widget shimmer loading yang bergerak sebagai pengganti CircularProgressIndicator.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({super.key, this.type = ShimmerType.dashboard});
  final ShimmerType type;

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
        if (widget.type == ShimmerType.dashboard) {
          return _buildDashboardShimmer();
        } else {
          return _buildRecapShimmer();
        }
      },
    );
  }

  Widget _buildDashboardShimmer() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(height: 160, borderRadius: 24),
          const SizedBox(height: 24),
          _buildShimmerBox(height: 24, width: 140, borderRadius: 6), // Akses Cepat Title
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(height: 124, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(height: 124, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(height: 124, borderRadius: 16)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(height: 124, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildShimmerBox(height: 240, width: double.infinity, borderRadius: 24), // Chart
          const SizedBox(height: 32),
          _buildShimmerBox(height: 24, width: 160, borderRadius: 6), // Transaksi Terbaru Title
          const SizedBox(height: 12),
          _buildShimmerListItem(),
          const SizedBox(height: 12),
          _buildShimmerListItem(),
        ],
      ),
    );
  }

  Widget _buildRecapShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bagian Header (Segmented Button & Date Navigator)
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildShimmerBox(height: 40, borderRadius: 24),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildShimmerBox(height: 64, borderRadius: 12),
              ),
            ],
          ),
        ),
        // Bagian Scrollable (Kartu Rekap, Chart, List)
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildShimmerBox(height: 160, borderRadius: 24), // Total Rekap
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildShimmerBox(height: 100, borderRadius: 20)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildShimmerBox(height: 100, borderRadius: 20)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildShimmerBox(height: 100, borderRadius: 20)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildShimmerBox(height: 100, borderRadius: 20)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildShimmerBox(height: 240, borderRadius: 24), // Chart
                const SizedBox(height: 24),
                _buildShimmerListItem(),
                const SizedBox(height: 12),
                _buildShimmerListItem(),
              ],
            ),
          ),
        ),
      ],
    );
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

  Widget _buildShimmerBox({required double height, required double borderRadius, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: _shimmerGradient,
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildShimmerBox(height: 48, width: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(height: 14, width: double.infinity, borderRadius: 4),
                const SizedBox(height: 8),
                _buildShimmerBox(height: 12, width: 100, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildShimmerBox(height: 16, width: 60, borderRadius: 4),
        ],
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
              _buildShimmerBox(height: 120, width: double.infinity, borderRadius: 20),
              const SizedBox(height: 16),
              _buildShimmerBox(height: 48, width: double.infinity, borderRadius: 12),
              const SizedBox(height: 16),
              ...List.generate(widget.itemCount, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildShimmerListItem(),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({required double height, required double borderRadius, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: _shimmerGradient,
      ),
    );
  }

  Widget _buildShimmerListItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildShimmerBox(height: 48, width: 48, borderRadius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmerBox(height: 14, width: double.infinity, borderRadius: 4),
                const SizedBox(height: 8),
                _buildShimmerBox(height: 12, width: 100, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildShimmerBox(height: 16, width: 60, borderRadius: 4),
        ],
      ),
    );
  }
}
