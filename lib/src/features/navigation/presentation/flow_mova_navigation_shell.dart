import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/flow_mova_colors.dart';
import '../../../shared/widgets/flow_mova_app_bar_title.dart';
import '../../../shared/widgets/flow_mova_logo.dart';

class FlowMovaNavigationShell extends StatelessWidget {
  const FlowMovaNavigationShell({
    required this.selectedRoute,
    required this.child,
    super.key,
    this.title,
    this.contentScrolls = true,
    this.maxContentWidth = 760,
    this.contentPadding = const EdgeInsets.all(24),
    this.actions = const [],
  });

  final String selectedRoute;
  final Widget child;
  final String? title;
  final bool contentScrolls;
  final double maxContentWidth;
  final EdgeInsetsGeometry contentPadding;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useBottomNavigation = constraints.maxWidth < 720;
        final content = _NavigationContent(
          selectedRoute: selectedRoute,
          scrolls: contentScrolls,
          maxWidth: maxContentWidth,
          padding: contentPadding,
          child: child,
        );
        final canPop = Navigator.canPop(context);

        if (useBottomNavigation) {
          return Scaffold(
            appBar: AppBar(
              titleSpacing: canPop ? 4 : null,
              title: FlowMovaAppBarTitle(title: _pageTitle, showLogo: !canPop),
              actions: actions,
            ),
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _goToIndex(context, index),
              destinations: _destinations
                  .map(
                    (destination) => NavigationDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: destination.label,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _goToIndex(context, index),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: FlowMovaLogo(
                      variant: FlowMovaLogoVariant.mark,
                      width: 72,
                      height: 72,
                    ),
                  ),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                      )
                      .toList(growable: false),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _LargeTopBar(title: _pageTitle, actions: actions),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _selectedIndex => switch (selectedRoute) {
    AppRoutes.tickets => 1,
    AppRoutes.profile => 2,
    AppRoutes.business => 3,
    _ => 0,
  };

  String get _pageTitle => title ?? _destinations[_selectedIndex].label;

  void _goToIndex(BuildContext context, int index) {
    final targetRoute = _destinations[index].route;

    if (targetRoute == selectedRoute) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(context, targetRoute, (_) => false);
  }
}

class _LargeTopBar extends StatelessWidget {
  const _LargeTopBar({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FlowMovaColors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (Navigator.canPop(context)) ...[
                  const BackButton(),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FlowMovaColors.logoInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  ...actions,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _destinations = [
  _FlowMovaDestination(
    route: AppRoutes.client,
    label: 'Accueil',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search,
  ),
  _FlowMovaDestination(
    route: AppRoutes.tickets,
    label: 'Tickets',
    icon: Icons.confirmation_number_outlined,
    selectedIcon: Icons.confirmation_number,
  ),
  _FlowMovaDestination(
    route: AppRoutes.profile,
    label: 'Profil',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
  _FlowMovaDestination(
    route: AppRoutes.business,
    label: 'Entreprise',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
  ),
];

class _FlowMovaDestination {
  const _FlowMovaDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavigationContent extends StatelessWidget {
  const _NavigationContent({
    required this.selectedRoute,
    required this.child,
    required this.scrolls,
    required this.maxWidth,
    required this.padding,
  });

  final String selectedRoute;
  final Widget child;
  final bool scrolls;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final constrainedChild = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.015),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(key: ValueKey(selectedRoute), child: child),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: FlowMovaColors.cloud,
      child: SafeArea(
        top: false,
        child: scrolls
            ? SingleChildScrollView(child: constrainedChild)
            : constrainedChild,
      ),
    );
  }
}
