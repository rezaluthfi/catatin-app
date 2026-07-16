/// Widget footer global untuk disematkan di bagian bawah menu navigasi utama.
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppFooter extends StatelessWidget {
  final bool hasFAB;

  const AppFooter({
    super.key,
    this.hasFAB = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        bottom: hasFAB ? 88 : 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(
            Icons.copyright_rounded,
            size: 13,
            color: AppColors.textDisabled,
          ),
          SizedBox(width: 4),
          Text(
            'KKN-PPM UGM Alor Carita 2026',
            style: TextStyle(
              fontFamily: 'GoogleSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
