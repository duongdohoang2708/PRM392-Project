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
  final List<HomeSectionId> desktopBottomFullWidth;
  final String greetingSubtitle;
  final bool compactUpNext;

  const HomeLayoutConfig({
    required this.mobileOrder,
    required this.desktopLeft,
    required this.desktopRight,
    this.desktopFullWidth = const [],
    this.desktopBottomFullWidth = const [],
    required this.greetingSubtitle,
    this.compactUpNext = false,
  });

  static const _defaultLayout = HomeLayoutConfig(
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
    ],
    desktopBottomFullWidth: [
      HomeSectionId.projects,
    ],
    greetingSubtitle: "Let's make today productive!",
  );

  /// All theme modes share the same home dashboard layout.
  static HomeLayoutConfig forMode(ActivityModeId mode) => _defaultLayout;
}
