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
  });

  final String selectedRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useBottomNavigation = constraints.maxWidth < 720;
        final content = _NavigationContent(
          selectedRoute: selectedRoute,
          child: child,
        );

        if (useBottomNavigation) {
          return Scaffold(
            appBar: AppBar(title: FlowMovaAppBarTitle(title: _pageTitle)),
            body: content,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _goToIndex(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: 'Tickets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Entreprise',
                ),
              ],
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
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search),
                      label: Text('Accueil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.confirmation_number_outlined),
                      selectedIcon: Icon(Icons.confirmation_number),
                      label: Text('Tickets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: Text('Profil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront),
                      label: Text('Entreprise'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
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

  String get _pageTitle => switch (selectedRoute) {
    AppRoutes.tickets => 'Tickets',
    AppRoutes.profile => 'Profil',
    AppRoutes.business => 'Entreprise',
    _ => 'Accueil',
  };

  void _goToIndex(BuildContext context, int index) {
    final targetRoute = switch (index) {
      1 => AppRoutes.tickets,
      2 => AppRoutes.profile,
      3 => AppRoutes.business,
      _ => AppRoutes.client,
    };

    if (targetRoute == selectedRoute) {
      return;
    }

    Navigator.pushReplacementNamed(context, targetRoute);
  }
}

class _NavigationContent extends StatelessWidget {
  const _NavigationContent({required this.selectedRoute, required this.child});

  final String selectedRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FlowMovaColors.cloud,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                  child: KeyedSubtree(
                    key: ValueKey(selectedRoute),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
