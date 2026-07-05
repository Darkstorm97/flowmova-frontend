import 'package:flutter/material.dart';

import '../features/business/presentation/business_home_screen.dart';
import '../features/client/presentation/client_home_screen.dart';
import '../features/navigation/presentation/flow_mova_navigation_shell.dart';
import '../features/placeholders/presentation/feature_placeholder_screen.dart';
import '../features/placeholders/presentation/not_found_screen.dart';
import '../features/profile/presentation/profile_home_screen.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.client;

    final Widget page = switch (routeName) {
      AppRoutes.client ||
      AppRoutes.clientAlias => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.client,
        child: ClientHomeScreen(),
      ),
      AppRoutes.profile => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.profile,
        child: ProfileHomeScreen(),
      ),
      AppRoutes.business => const FlowMovaNavigationShell(
        selectedRoute: AppRoutes.business,
        child: BusinessHomeScreen(),
      ),
      AppRoutes.login => const FeaturePlaceholderScreen(
        title: 'Connexion',
        description:
            'Le formulaire de connexion sera implemente dans AUTH-FRONT-002.',
      ),
      AppRoutes.register => const FeaturePlaceholderScreen(
        title: 'Creer un compte',
        description:
            'Le formulaire d inscription sera implemente dans AUTH-FRONT-001.',
      ),
      AppRoutes.businessDashboard => const FeaturePlaceholderScreen(
        title: 'Dashboard entreprise',
        description:
            'Le dashboard admin sera branche avec les features entreprise.',
      ),
      AppRoutes.companyDetail => const FeaturePlaceholderScreen(
        title: 'Detail entreprise',
        description:
            'La fiche publique entreprise sera implementee dans PUBLIC-FRONT-002.',
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
      AppRoutes.ticketLookup => const FeaturePlaceholderScreen(
        title: 'Consulter un ticket',
        description:
            'La recherche par numero sera implementee dans TICKET-FRONT-002.',
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

    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
