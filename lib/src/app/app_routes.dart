abstract final class AppRoutes {
  static const client = '/';
  static const clientAlias = '/client';
  static const tickets = '/tickets';
  static const profile = '/profile';
  static const business = '/business';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const businessDashboard = '/business/dashboard';
  static const businessCatalog = '/business/catalog';
  static const businessTickets = '/business/tickets';
  static const businessTicketDetail = '/business/tickets/detail';
  static const createCompany = '/business/companies/create';
  static const editCompany = '/business/companies/edit';
  static const businessServiceUnits = '/business/service-units';
  static const businessServiceUnitLocations =
      '/business/service-units/locations';
  static const businessServiceUnitItems = '/business/service-units/items';
  static const businessServiceUnitTickets = '/business/service-units/tickets';
  static const companyDetail = '/companies/detail';
  static const serviceUnitDetail = '/service-units/detail';
  static const publicLocationDetail = '/locations/public';
  static const createTicket = '/tickets/create';
  static const ticketCreationSuccess = '/tickets/create/success';
  static const ticketLookup = '/tickets/lookup';
  static const recentTickets = '/tickets/recent';
  static const myTickets = '/users/me/tickets';
  static const myTicketDetail = '/users/me/tickets/detail';
  static const myCompanies = '/users/me/companies';
}
