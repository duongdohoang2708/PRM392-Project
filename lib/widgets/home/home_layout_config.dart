import '../../models/activity_mode.dart';

enum HomeSectionId {
  greeting,
  overview,
  streak,
  activeFocus,
  upNext,
  smartLists,
  projects,
  quickActions,
}

class HomeLayoutConfig {
  final List<HomeSectionId> mobileOrder;
  final List<HomeSectionId> desktopLeft;
  final List<HomeSectionId> desktopRight;
  final List<HomeSectionId> desktopFullWidth;
  final String greetingSubtitle;
  final bool compactUpNext;

  const HomeLayoutConfig({
    required this.mobileOrder,
    required this.desktopLeft,
    required this.desktopRight,
    this.desktopFullWidth = const [],
    required this.greetingSubtitle,
    this.compactUpNext = false,
  });

  static HomeLayoutConfig forMode(ActivityModeId mode) {
    return switch (mode) {
      ActivityModeId.defaultMode => const HomeLayoutConfig(
          mobileOrder: [
            HomeSectionId.greeting,
            HomeSectionId.overview,
            HomeSectionId.streak,
            HomeSectionId.activeFocus,
            HomeSectionId.upNext,
            HomeSectionId.smartLists,
            HomeSectionId.projects,
            HomeSectionId.quickActions,
          ],
          desktopLeft: [
            HomeSectionId.activeFocus,
            HomeSectionId.upNext,
          ],
          desktopRight: [
            HomeSectionId.smartLists,
            HomeSectionId.quickActions,
          ],
          desktopFullWidth: [
            HomeSectionId.greeting,
            HomeSectionId.overview,
            HomeSectionId.streak,
            HomeSectionId.projects,
          ],
          greetingSubtitle: "Let's make today productive!",
        ),
      ActivityModeId.work => const HomeLayoutConfig(
          mobileOrder: [
            HomeSectionId.greeting,
            HomeSectionId.overview,
            HomeSectionId.upNext,
            HomeSectionId.activeFocus,
            HomeSectionId.projects,
            HomeSectionId.smartLists,
            HomeSectionId.quickActions,
            HomeSectionId.streak,
          ],
          desktopLeft: [
            HomeSectionId.upNext,
            HomeSectionId.activeFocus,
          ],
          desktopRight: [
            HomeSectionId.smartLists,
            HomeSectionId.quickActions,
          ],
          desktopFullWidth: [
            HomeSectionId.greeting,
            HomeSectionId.overview,
            HomeSectionId.projects,
            HomeSectionId.streak,
          ],
          greetingSubtitle: 'Focus on what matters at work.',
        ),
      ActivityModeId.study => const HomeLayoutConfig(
          mobileOrder: [
            HomeSectionId.greeting,
            HomeSectionId.smartLists,
            HomeSectionId.activeFocus,
            HomeSectionId.upNext,
            HomeSectionId.overview,
            HomeSectionId.quickActions,
          ],
          desktopLeft: [
            HomeSectionId.smartLists,
            HomeSectionId.activeFocus,
          ],
          desktopRight: [
            HomeSectionId.upNext,
            HomeSectionId.quickActions,
          ],
          desktopFullWidth: [
            HomeSectionId.greeting,
            HomeSectionId.overview,
          ],
          greetingSubtitle: 'Time to learn and grow.',
        ),
      ActivityModeId.chill => const HomeLayoutConfig(
          mobileOrder: [
            HomeSectionId.greeting,
            HomeSectionId.quickActions,
            HomeSectionId.projects,
            HomeSectionId.upNext,
          ],
          desktopLeft: [
            HomeSectionId.quickActions,
          ],
          desktopRight: [
            HomeSectionId.projects,
          ],
          desktopFullWidth: [
            HomeSectionId.greeting,
            HomeSectionId.upNext,
          ],
          greetingSubtitle: 'Take it easy — you earned a break.',
        ),
      ActivityModeId.sleep => const HomeLayoutConfig(
          mobileOrder: [
            HomeSectionId.greeting,
            HomeSectionId.upNext,
          ],
          desktopLeft: [
            HomeSectionId.upNext,
          ],
          desktopRight: [],
          desktopFullWidth: [
            HomeSectionId.greeting,
          ],
          greetingSubtitle: 'Wind down. Tomorrow can wait.',
          compactUpNext: true,
        ),
    };
  }
}
