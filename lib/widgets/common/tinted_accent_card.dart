import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'accent_icon_well.dart';

enum TintedAccentCardVariant {
  /// Overview-style: icon well, border, value + label.
  overview,

  /// Quick action: flat tint, icon + label only.
  action,

  /// Statistics-style: border, accent-tinted icon well, larger padding.
  statistics,
}

class TintedAccentCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String? label;
  final String? value;
  final VoidCallback? onTap;
  final TintedAccentCardVariant variant;
  final double lightBgAlpha;
  final double darkBgAlpha;

  const TintedAccentCard({
    super.key,
    required this.accentColor,
    required this.icon,
    this.label,
    this.value,
    this.onTap,
    this.variant = TintedAccentCardVariant.overview,
    this.lightBgAlpha = 0.28,
    this.darkBgAlpha = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.statCardBgOf(
      context,
      accentColor,
      lightAlpha: lightBgAlpha,
      darkAlpha: darkBgAlpha,
    );

    final content = switch (variant) {
      TintedAccentCardVariant.overview => _buildOverviewContent(context),
      TintedAccentCardVariant.action => _buildActionContent(context),
      TintedAccentCardVariant.statistics => _buildStatisticsContent(context),
    };

    final padding = switch (variant) {
      TintedAccentCardVariant.overview =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      TintedAccentCardVariant.action =>
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      TintedAccentCardVariant.statistics => const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
    };

    final borderRadius = switch (variant) {
      TintedAccentCardVariant.statistics => 18.0,
      _ => 16.0,
    };

    final decoration = BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(borderRadius),
      border: variant == TintedAccentCardVariant.action
          ? Border.all(color: AppColors.borderOf(context), width: 1.0)
          : Border.all(
              color: AppColors.statCardBorderOf(context, accentColor),
              width: 2.0,
            ),
    );

    final child = Container(
      padding: padding,
      decoration: decoration,
      child: content,
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _buildOverviewContent(BuildContext context) {
    return Row(
      children: [
        AccentIconWell(
          accentColor: accentColor,
          icon: icon,
          iconSize: 20,
          padding: const EdgeInsets.all(6),
          borderRadius: 10,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionContent(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.projectAccentOf(context, accentColor), size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsContent(BuildContext context) {
    return Row(
      children: [
        AccentIconWell(
          accentColor: accentColor,
          icon: icon,
          size: 34,
          iconSize: 20,
          borderRadius: 10,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (value != null)
                Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              if (label != null)
                Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
