import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../models/activity_mode.dart';

import '../../providers/activity_mode_provider.dart';

import '../../theme/app_colors.dart';

import '../../widgets/settings/settings_screen_shell.dart';

import '../../widgets/settings/settings_widgets.dart';

import '../../widgets/settings/theme_mode_nav_tile.dart';

import '../../widgets/statistics/statistics_widgets.dart';



class ActivityModesScreen extends StatelessWidget {

  const ActivityModesScreen({super.key});



  @override

  Widget build(BuildContext context) {

    final activityModes = context.watch<ActivityModeProvider>();

    final active = activityModes.activeDefinition;



    return SettingsScreenShell(

      activeRoute: '/settings',

      title: 'Theme Modes',

      showBack: true,

      child: Column(

        children: [

          StatPanel(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  'Active now',

                  style: TextStyle(

                    color: AppColors.textSecondaryOf(context),

                    fontSize: 13,

                    fontWeight: FontWeight.w600,

                  ),

                ),

                const SizedBox(height: 12),

                Row(

                  children: [

                    Container(

                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(

                        color: AppColors.primaryLightTintOf(context),

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: Icon(

                        active.icon,

                        color: AppColors.primaryDarkOf(context),

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      child: Text(

                        active.name,

                        style: TextStyle(

                          color: AppColors.textPrimaryOf(context),

                          fontSize: 18,

                          fontWeight: FontWeight.w800,

                        ),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

          const SizedBox(height: 16),

          SettingsSection(

            title: 'Modes',

            children: [

              for (final preset in ActivityModes.presets)

                ThemeModeNavTile(

                  icon: preset.icon,

                  title: preset.name,

                  subtitle: activityModes.scheduleLabelFor(preset.id),

                  isActive: activityModes.activeModeId == preset.id,

                  onTap: () => Navigator.pushNamed(

                    context,

                    '/settings/activity-modes/detail',

                    arguments: {'modeId': preset.id.name},

                  ),

                ),

            ],

          ),

        ],

      ),

    );

  }

}

