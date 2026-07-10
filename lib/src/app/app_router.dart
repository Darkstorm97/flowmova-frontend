import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/business/presentation/business_dashboard_screen.dart';
import '../features/business/presentation/business_service_units_screen.dart';
import '../features/business/presentation/create_company_screen.dart';
import '../features/business/presentation/edit_company_screen.dart';
import '../features/business/presentation/my_companies_screen.dart';
import '../features/client/data/company_search_gateway.dart';
import '../features/client/presentation/company_detail_screen.dart';
import '../features/client/presentation/client_home_screen.dart';
import '../features/client/presentation/public_location_screen.dart';
import '../features/navigation/presentation/flow_mova_navigation_shell.dart';
import '../features/placeholders/presentation/feature_placeholder_screen.dart';
import '../features/placeholders/presentation/not_found_screen.dart';
import '../features/profile/presentation/profile_home_screen.dart';
import '../features/tickets/data/recent_ticket_storage.dart';
import '../features/tickets/presentation/my_tickets_screen.dart';
import '../features/tickets/presentation/recent_tickets_screen.dart';
import '../features/tickets/presentation/ticket_lookup_screen.dart';
import '../features/tickets/presentation/tickets_home_screen.dart';
import '../core/session/session_scope.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    CompanySearchGateway? companySearchGateway,
    RecentTicketStorage? recentTicketStorage,
  }) {
    final routeName = settings.name ?? AppRoutes.client;
    final routeUri = Uri.tryParse(routeName) ?? Uri(path: routeName);
    final normalizedPath = routeUri.path.split(';').first;
    final routePath = normalizedPath.isEmpty
        ? AppRoutes.client
        : normalizedPath;

    final Widget page = switch (routePath) {
      AppRoutes.client || AppRoutes.clientAlias => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        child: ClientHomeScreen(searchGateway: companySearchGateway),
      ),
      AppRoutes.profile => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.profile,
        contentScrolls: false,
        child: ProfileHomeScreen(),
      ),
      AppRoutes.tickets => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        child: TicketsHomeScreen(recentTicketStorage: recentTicketStorage),
      ),
      AppRoutes.business ||
      AppRoutes.myCompanies => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Mes entreprises',
        contentScrolls: false,
        actions: [_CreateCompanyAction()],
        child: MyCompaniesScreen(),
      ),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.createCompany => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Nouvelle entreprise',
        contentScrolls: false,
        child: CreateCompanyScreen(),
      ),
      AppRoutes.editCompany => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Modifier entreprise',
        contentScrolls: false,
        child: _editCompanyPage(settings.arguments),
      ),
      AppRoutes.businessDashboard => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Dashboard entreprise',
        contentScrolls: false,
        child: _businessDashboardPage(settings.arguments),
      ),
      AppRoutes.businessServiceUnits => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Services',
        contentScrolls: false,
        child: _businessServiceUnitsPage(settings.arguments),
      ),
      AppRoutes.businessServiceUnitLocations => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        title: 'Emplacements',
        contentScrolls: false,
        child: _businessServiceUnitLocationsPage(settings.arguments),
      ),
      AppRoutes.companyDetail => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        title: 'Entreprise',
        contentScrolls: false,
        maxContentWidth: 760,
        contentPadding: EdgeInsets.zero,
        child: _companyDetailPage(
          settings.arguments,
          recentTicketStorage: recentTicketStorage,
        ),
      ),
      AppRoutes.serviceUnitDetail => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        title: 'Unite de service',
        child: FeaturePlaceholderScreen(
          title: 'Detail unite de service',
          description:
              'Le detail unite de service sera implemente dans PUBLIC-FRONT-003.',
        ),
      ),
      AppRoutes.publicLocationDetail => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        title: 'QR code',
        contentScrolls: false,
        maxContentWidth: 680,
        contentPadding: EdgeInsets.zero,
        child: _publicLocationPage(
          settings.arguments,
          routeUri: routeUri,
          routeName: routeName,
          recentTicketStorage: recentTicketStorage,
        ),
      ),
      AppRoutes.createTicket => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        title: 'Creer un ticket',
        child: FeaturePlaceholderScreen(
          title: 'Creer un ticket',
          description:
              'La creation de ticket sera implementee dans TICKET-FRONT-001.',
        ),
      ),
      AppRoutes.ticketLookup => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        title: 'Voir un ticket',
        contentScrolls: false,
        child: TicketLookupScreen(
          arguments: _ticketLookupArguments(settings.arguments),
          recentTicketStorage: recentTicketStorage,
        ),
      ),
      AppRoutes.recentTickets => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        title: 'Tickets recents',
        contentScrolls: false,
        child: RecentTicketsScreen(recentTicketStorage: recentTicketStorage),
      ),
      AppRoutes.myTickets => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        title: 'Mes tickets',
        contentScrolls: false,
        child: MyTicketsScreen(),
      ),
      AppRoutes.myTicketDetail => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        title: 'Tickets',
        contentScrolls: false,
        child: _myTicketDetailPage(settings.arguments),
      ),
      _ => NotFoundScreen(routeName: routeName),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final incomingOffset = Tween<Offset>(
          begin: const Offset(0.025, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);
        final outgoingOpacity = Tween<double>(
          begin: 1,
          end: 0.92,
        ).animate(secondaryAnimation);

        return FadeTransition(
          opacity: animation,
          child: FadeTransition(
            opacity: outgoingOpacity,
            child: SlideTransition(position: incomingOffset, child: child),
          ),
        );
      },
    );
  }

  static Widget _publicLocationPage(
    Object? arguments, {
    required Uri routeUri,
    required String routeName,
    RecentTicketStorage? recentTicketStorage,
  }) {
    final initialSlug = arguments is String
        ? arguments
        : routeUri.queryParameters['slug'] ??
              _matrixParameter(routeName, 'slug');

    return PublicLocationScreen(
      initialSlug: initialSlug,
      recentTicketStorage: recentTicketStorage,
    );
  }

  static String? _matrixParameter(String routeName, String key) {
    final match = RegExp('(?:^|;)$key=([^;?]+)').firstMatch(routeName);
    final value = match?.group(1);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return Uri.decodeComponent(value.trim());
  }

  static Widget _companyDetailPage(
    Object? arguments, {
    RecentTicketStorage? recentTicketStorage,
  }) {
    final companyId = arguments is String ? arguments : null;
    if (companyId == null || companyId.trim().isEmpty) {
      return const FeaturePlaceholderScreen(
        title: 'Entreprise introuvable',
        description:
            'Revenez a l accueil et selectionnez une entreprise dans le flux.',
      );
    }

    return CompanyDetailScreen(
      companyId: companyId,
      recentTicketStorage: recentTicketStorage,
    );
  }

  static TicketLookupArguments? _ticketLookupArguments(Object? arguments) {
    if (arguments is TicketLookupArguments) {
      return arguments;
    }
    return null;
  }

  static Widget _myTicketDetailPage(Object? arguments) {
    if (arguments is MyTicketDetailArguments) {
      return MyTicketDetailScreen(
        ticket: arguments.ticket,
        gateway: arguments.gateway,
      );
    }

    return const FeaturePlaceholderScreen(
      title: 'Ticket introuvable',
      description: 'Revenez a Mes tickets et selectionnez un ticket.',
    );
  }

  static Widget _editCompanyPage(Object? arguments) {
    if (arguments is EditCompanyArguments) {
      return EditCompanyScreen(
        company: arguments.company,
        gateway: arguments.gateway,
      );
    }

    return const FeaturePlaceholderScreen(
      title: 'Entreprise introuvable',
      description: 'Revenez a Mes entreprises et selectionnez Modifier.',
    );
  }

  static Widget _businessDashboardPage(Object? arguments) {
    final companyId = arguments is String ? arguments : null;
    if (companyId == null || companyId.trim().isEmpty) {
      return const FeaturePlaceholderScreen(
        title: 'Entreprise introuvable',
        description:
            'Revenez a Mes entreprises et selectionnez une entreprise.',
      );
    }

    return BusinessDashboardScreen(companyId: companyId);
  }

  static Widget _businessServiceUnitsPage(Object? arguments) {
    if (arguments is BusinessServiceUnitsArguments) {
      return BusinessServiceUnitsScreen(companyId: arguments.companyId);
    }

    return const FeaturePlaceholderScreen(
      title: 'Entreprise introuvable',
      description: 'Revenez au dashboard et ouvrez les services.',
    );
  }

  static Widget _businessServiceUnitLocationsPage(Object? arguments) {
    if (arguments is BusinessServiceUnitLocationsArguments) {
      return BusinessServiceUnitLocationsScreen(
        companyId: arguments.companyId,
        serviceUnit: arguments.serviceUnit,
      );
    }

    return const FeaturePlaceholderScreen(
      title: 'Service introuvable',
      description:
          'Revenez a la liste des services et selectionnez un service.',
    );
  }
}

class _CreateCompanyAction extends StatelessWidget {
  const _CreateCompanyAction();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    if (!session.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.icon(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createCompany),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }
}
