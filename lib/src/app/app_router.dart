import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/business/presentation/business_home_screen.dart';
import '../features/client/data/company_search_gateway.dart';
import '../features/client/presentation/company_detail_screen.dart';
import '../features/client/presentation/client_home_screen.dart';
import '../features/navigation/presentation/flow_mova_navigation_shell.dart';
import '../features/placeholders/presentation/feature_placeholder_screen.dart';
import '../features/placeholders/presentation/not_found_screen.dart';
import '../features/profile/presentation/profile_home_screen.dart';
import '../features/tickets/data/recent_ticket_storage.dart';
import '../features/tickets/presentation/recent_tickets_screen.dart';
import '../features/tickets/presentation/ticket_lookup_screen.dart';
import '../features/tickets/presentation/tickets_home_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    CompanySearchGateway? companySearchGateway,
    RecentTicketStorage? recentTicketStorage,
  }) {
    final routeName = settings.name ?? AppRoutes.client;

    final Widget page = switch (routeName) {
      AppRoutes.client || AppRoutes.clientAlias => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        child: ClientHomeScreen(searchGateway: companySearchGateway),
      ),
      AppRoutes.profile => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.profile,
        child: ProfileHomeScreen(),
      ),
      AppRoutes.tickets => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        child: TicketsHomeScreen(recentTicketStorage: recentTicketStorage),
      ),
      AppRoutes.business => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        child: BusinessHomeScreen(),
      ),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.register => const RegisterScreen(),
      AppRoutes.businessDashboard => const FeaturePlaceholderScreen(
        title: 'Dashboard entreprise',
        description:
            'Le dashboard admin sera branche avec les features entreprise.',
      ),
      AppRoutes.companyDetail => _companyDetailPage(
        settings.arguments,
        recentTicketStorage: recentTicketStorage,
      ),
      AppRoutes.serviceUnitDetail => const FeaturePlaceholderScreen(
        title: 'Detail unite de service',
        description:
            'Le detail unite de service sera implemente dans PUBLIC-FRONT-003.',
      ),
      AppRoutes.publicLocationDetail => const FeaturePlaceholderScreen(
        title: 'Emplacement public',
        description:
            'Le parcours QR code emplacement sera implemente dans PUBLIC-FRONT-004.',
      ),
      AppRoutes.createTicket => const FeaturePlaceholderScreen(
        title: 'Creer un ticket',
        description:
            'La creation de ticket sera implementee dans TICKET-FRONT-001.',
      ),
      AppRoutes.ticketLookup => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        child: TicketLookupScreen(
          arguments: _ticketLookupArguments(settings.arguments),
          recentTicketStorage: recentTicketStorage,
        ),
      ),
      AppRoutes.recentTickets => FlowMovaNavigationShell(
        selectedRoute: AppRoutes.tickets,
        child: RecentTicketsScreen(recentTicketStorage: recentTicketStorage),
      ),
      AppRoutes.myTickets => const FeaturePlaceholderScreen(
        title: 'Mes tickets',
        description:
            'La liste des tickets utilisateur sera branchee avec la session.',
      ),
      AppRoutes.myCompanies => const FeaturePlaceholderScreen(
        title: 'Mes entreprises',
        description:
            'La liste des entreprises admin sera implementee dans COMPANY-FRONT-001.',
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
}
