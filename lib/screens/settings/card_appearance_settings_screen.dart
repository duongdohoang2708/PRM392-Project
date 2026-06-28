import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/settings/settings_screen_shell.dart';
import '../../widgets/common/tinted_accent_card.dart';
import '../../widgets/statistics/statistics_widgets.dart';

class CardAppearanceSettingsScreen extends StatelessWidget {
  const CardAppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final solidity = settings.cardFillSolidity;
    final tintStrength = settings.cardTintStrength;
    final transparentPercent = ((1 - solidity) * 100).round();
    final tintLabel = settings.cardTintStrengthLabel;

    return SettingsScreenShell(
      activeRoute: '/settings',
      title: 'Card appearance',
      showBack: true,
      child: StatPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card background',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  transparentPercent == 0
                      ? 'Solid'
                      : transparentPercent == 100
                          ? 'Transparent'
                          : '$transparentPercent% transparent',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: solidity,
              min: SettingsProvider.minCardFillSolidity,
              max: SettingsProvider.maxCardFillSolidity,
              divisions: 20,
              label: transparentPercent == 0
                  ? 'Solid'
                  : '$transparentPercent% transparent',
              activeColor: AppColors.primaryDark,
              inactiveColor: AppColors.borderOf(context),
              onChanged: settings.setCardFillSolidity,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transparent',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Solid',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card tint',
                  style: TextStyle(
                    color: AppColors.textPrimaryOf(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tintLabel,
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: tintStrength,
              min: SettingsProvider.minCardTintStrength,
              max: SettingsProvider.maxCardTintStrength,
              divisions: 20,
              label: tintLabel,
              activeColor: AppColors.primaryDark,
              inactiveColor: AppColors.borderOf(context),
              onChanged: settings.setCardTintStrength,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtle',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Strong',
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: settings.isDefaultCardAppearance
                    ? null
                    : () async {
                        await settings.resetCardAppearance();
                        if (context.mounted) {
                          AppNotification.showInfo(
                            context,
                            'Card appearance reset to default.',
                          );
                        }
                      },
                child: const Text('Reset to default'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preview',
              style: TextStyle(
                color: AppColors.textPrimaryOf(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 480;
                final cards = [
                  TintedAccentCard(
                    accentColor: AppColors.statBlue,
                    icon: Icons.water_drop_outlined,
                    label: 'Sessions',
                    value: '8',
                  ),
                  TintedAccentCard(
                    accentColor: AppColors.primaryDark,
                    icon: Icons.task_alt,
                    label: 'Tasks',
                    value: '12',
                  ),
                  TintedAccentCard(
                    accentColor: AppColors.accentYellow,
                    icon: Icons.timer_outlined,
                    label: 'Focus',
                    value: '45m',
                  ),
                  TintedAccentCard(
                    accentColor: const Color(0xFFD32F2F),
                    icon: Icons.event_busy_outlined,
                    label: 'Overdue',
                    value: '2',
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      cards[i],
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
