# FlowMova Frontend MVP Backlog

Ce document decrit les etapes frontend a implementer progressivement pour le MVP FlowMova.

Le frontend doit rester aligne avec:

- le scope FS-001 valide;
- les API backend deja exposees;
- les decisions de marque dans `docs/brand/flowmova-brand-guidelines.md`;
- la regle projet: aucune fonctionnalite n'est implementee sans discussion, validation documentaire et issue GitHub.

## Principes Frontend

- Application Flutter mobile-first, compatible Web, Android et iOS.
- Interface claire, fluide, joviale sans etre trop corporate.
- Police UI definitive: `Inter`.
- Police de marque/logo: `Nunito Sans`.
- Couleurs et logos valides depuis la documentation de marque.
- Les ecrans doivent etre branches sur le backend progressivement, sans faux parcours definitifs.
- Les erreurs backend standardisees doivent etre affichees proprement cote utilisateur.
- Les listes paginees doivent respecter la pagination backend.
- L'application est orientee client d'abord: l'ecran par defaut doit aider un client a trouver une entreprise et acceder aux services disponibles.
- L'espace entreprise reste visible, mais secondaire par rapport au parcours client.

## Navigation MVP

La navigation principale MVP doit etre organisee autour de quatre entrees:

- `Accueil`: entree par defaut de l'application. Elle contient la recherche d'entreprises actives, les filtres publics, l'acces aux fiches entreprises, aux unites de service et a la creation de ticket. Elle ne doit pas contenir le raccourci `Consulter un ticket par code`.
- `Tickets`: espace dedie au suivi des tickets. Il contient `Mes tickets`, reserve aux tickets du compte authentifie, `Recents sur cet appareil`, disponible authentifie ou non avec les tickets crees localement dans le navigateur ou l'application mobile du client, ainsi que `Voir un ticket avec le code`, accessible aux utilisateurs authentifies ou non.
- `Entreprise`: espace admin/entreprise. Si l'utilisateur n'est pas connecte, il propose `Se connecter` et `Creer un compte`. Si l'utilisateur est connecte, il contient `Creer une entreprise`, la liste des entreprises de l'utilisateur avec recherche/filtre, puis l'acces a la page d'administration d'une entreprise.
- `Profil`: espace compte. Si l'utilisateur n'est pas connecte, il propose `Se connecter` et `Creer un compte`. Si l'utilisateur est connecte, il contient `Mes infos profil`, les parametres, la deconnexion et les futures options de compte.

Sur mobile, cette navigation peut etre rendue sous forme de bottom navigation. Sur web/tablette, elle peut etre rendue en barre superieure. Le comportement fonctionnel reste le meme.

## Milestone 1 - Fondation Frontend

Objectif: transformer le projet Flutter de base en socle applicatif FlowMova.

### FRONT-001 - Initialiser la structure applicative Flutter

Creer l'architecture de dossiers et remplacer l'ecran compteur Flutter par l'application FlowMova.

Inclure:

- structure `lib/src`;
- point d'entree applicatif clair;
- separation `app`, `core`, `features`, `shared`;
- suppression du contenu demo Flutter;
- premier ecran d'accueil applicatif minimal.

Definition of Done:

- l'application demarre sans ecran demo Flutter;
- la structure est prete pour les features;
- `flutter test` passe.

### FRONT-002 - Integrer theme, couleurs et assets de marque

Configurer le theme Flutter depuis les guidelines FlowMova.

Inclure:

- palette MVP;
- typographie UI `Inter` avec fallback systeme;
- rayons, boutons, champs, badges de base;
- integration des assets logo valides;
- verification visuelle de base sur web/mobile.

Definition of Done:

- l'app utilise les couleurs FlowMova;
- le logo officiel est utilisable dans l'interface;
- les contrastes principaux sont valides pendant l'implementation.

### FRONT-003 - Configurer navigation et routes MVP

Mettre en place la navigation frontend.

Inclure routes pour:

- espace client par defaut (`/` ou `/client`);
- profil (`/profile`);
- espace entreprise (`/business`);
- connexion et inscription accessibles depuis le profil;
- dashboard admin accessible depuis l'espace entreprise;
- recherche/consultation d'entreprises depuis l'espace client;
- detail entreprise;
- detail unite de service;
- detail emplacement public;
- creation ticket;
- consultation ticket par numero;
- mes tickets;
- mes entreprises.

Definition of Done:

- les routes MVP existent;
- l'ecran par defaut est l'accueil client;
- la navigation principale expose `Accueil`, `Tickets`, `Entreprise` et `Profil`;
- les ecrans peuvent etre atteints sans logique metier complete;
- une route inconnue affiche un etat propre.

### FRONT-005 - Ajuster la navigation MVP avec l'onglet Tickets

Adapter le squelette de navigation apres validation de la navigation a quatre onglets.

Inclure:

- renommer l'entree `Client` en `Accueil`;
- ajouter l'onglet principal `Tickets`;
- retirer le raccourci `Consulter un ticket` de l'accueil;
- deplacer `Mes tickets` et `Voir un ticket avec le code` dans l'onglet `Tickets`;
- ajouter `Recents sur cet appareil` dans l'onglet `Tickets`;
- garder `Profil` pour les informations de compte, les parametres et la deconnexion;
- garder `Entreprise` pour la creation d'entreprise, la liste des entreprises et l'acces administration.

Definition of Done:

- la bottom navigation mobile et la navigation large exposent `Accueil`, `Tickets`, `Entreprise`, `Profil`;
- l'accueil ne propose plus la consultation directe d'un ticket par code;
- l'onglet `Tickets` affiche les entrees `Mes tickets`, `Recents sur cet appareil` et `Voir un ticket avec le code`;
- les tests widget couvrent cette navigation.

### FRONT-004 - Configurer environnement API

Centraliser la configuration backend.

Inclure:

- URL API locale par defaut: `http://localhost:8080`;
- possibilite de changer l'URL par environnement;
- conventions pour dev/prod;
- documentation de lancement local.

Definition of Done:

- le frontend sait cibler le backend local;
- la configuration n'est pas dupliquee dans les features.

## Milestone 2 - Couche API et Session

Objectif: poser une communication backend fiable avant les ecrans metier.

### FRONT-010 - Creer le client API HTTP

Creer le client HTTP commun pour appeler le backend.

Inclure:

- base URL;
- headers JSON;
- decodage JSON;
- timeout raisonnable;
- support futur du token JWT;
- gestion des codes HTTP.

Definition of Done:

- les features peuvent reutiliser un client unique;
- le client transforme les erreurs techniques en erreurs lisibles.

### FRONT-011 - Mapper les erreurs backend standardisees

Afficher correctement les erreurs renvoyees par l'API backend.

Inclure:

- modele d'erreur API;
- mapping validation, authentification, autorisation, conflit, non trouve;
- message utilisateur simple;
- preservation d'un message technique pour debug si necessaire.

Definition of Done:

- une erreur backend standardisee peut etre affichee dans un formulaire;
- les erreurs reseau ont un message dedie.

### FRONT-012 - Gerer la session authentifiee

Mettre en place la session utilisateur.

Inclure:

- stockage du JWT;
- ajout automatique du token aux requetes authentifiees;
- detection session absente ou expiree;
- deconnexion locale;
- etat global minimal de session.

Definition of Done:

- un utilisateur connecte reste connecte apres redemarrage de l'app quand possible;
- les appels authentifies utilisent le JWT;
- la deconnexion nettoie la session.

## Milestone 3 - Authentification

Objectif: permettre a un utilisateur de creer un compte, se connecter et acceder a son espace.

### AUTH-FRONT-001 - Creer l'ecran d'inscription

Brancher l'inscription utilisateur sur le backend.

Inclure:

- formulaire inscription;
- validations frontend minimales;
- affichage des erreurs backend;
- redirection apres succes.

Definition of Done:

- un utilisateur peut creer un compte depuis le frontend;
- les erreurs de validation sont visibles.

### AUTH-FRONT-002 - Creer l'ecran de connexion

Brancher la connexion utilisateur sur le backend.

Inclure:

- formulaire connexion;
- recuperation JWT;
- stockage session;
- redirection vers dashboard.

Definition of Done:

- un utilisateur peut se connecter;
- le token est conserve;
- l'utilisateur arrive dans son espace.

### AUTH-FRONT-003 - Creer l'ecran profil utilisateur

Afficher les informations du compte connecte.

Inclure:

- etat non connecte avec boutons `Se connecter` et `Creer un compte`;
- affichage `Mes infos profil` si l'utilisateur est connecte;
- acces futur aux parametres et a la deconnexion si l'utilisateur est connecte;
- appel API profil;
- etat chargement;
- etat erreur;
- bouton deconnexion.

Definition of Done:

- un utilisateur non connecte comprend comment se connecter ou creer un compte;
- l'utilisateur connecte peut voir son profil;
- il peut se deconnecter.

## Milestone 4 - Parcours Public Client

Objectif: permettre a un client de trouver une entreprise, consulter ses services et creer ou suivre un ticket.

### PUBLIC-FRONT-001 - Rechercher et lister les entreprises actives

Brancher la recherche publique d'entreprises.

Inclure:

- implementation dans l'accueil client;
- recherche texte;
- filtre type/domaine d'entreprise;
- filtres ville, region, pays;
- pagination;
- affichage fiche entreprise.

Definition of Done:

- un utilisateur peut rechercher les entreprises actives;
- les filtres backend disponibles sont exploites.
- la recherche est le contenu principal de l'accueil client.

### PUBLIC-FRONT-002 - Consulter la fiche publique entreprise

Afficher le detail public d'une entreprise active.

Inclure:

- nom, description, domaine, devise;
- adresse si renseignee;
- unites de service visibles;
- categories/catalogues accessibles selon le parcours valide.

Definition of Done:

- la fiche entreprise permet de comprendre ou creer une demande.

### PUBLIC-FRONT-003 - Consulter une unite de service et ses emplacements

Afficher une unite de service et ses emplacements disponibles.

Inclure:

- detail unite de service;
- emplacement par defaut;
- autres emplacements;
- lien vers creation ticket.

Definition of Done:

- un utilisateur peut choisir ou rattacher sa demande.

### PUBLIC-FRONT-004 - Consulter le parcours QR code emplacement

Afficher la page publique ouverte depuis le lien QR code.

Inclure:

- chargement par lien public;
- affichage unite de service;
- affichage emplacement;
- articles disponibles de l'unite de service;
- bouton creation ticket.

Definition of Done:

- un client arrivant depuis QR code peut comprendre ou il est et creer un ticket.

### TICKET-FRONT-001 - Creer un ticket public ou authentifie

Brancher la creation de ticket.

Inclure:

- implementation dans l'onglet `Tickets`;
- support utilisateur connecte;
- support invite avec `guestName` requis;
- telephone optionnel;
- choix emplacement;
- lignes d'articles avec quantite optionnelle par defaut a 1;
- affichage numero de ticket et code d'acces si applicable;
- enregistrement local du ticket cree dans `Recents sur cet appareil` si un `accessCode` est retourne ou si les informations minimales sont disponibles;
- application du mode `AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET` pour les visiteurs non authentifies: si un ticket recent ouvert existe deja localement pour la meme unite, proposer d'ouvrir le ticket existant au lieu de recreer.

Definition of Done:

- un client peut creer un ticket depuis l'application ou un QR code;
- le retour backend est affiche clairement;
- les tickets invites crees depuis le navigateur ou l'application mobile sont conserves dans les recents locaux.

### TICKET-FRONT-002 - Consulter un ticket par numero

Permettre la consultation simple d'un ticket par son numero plateforme.

Inclure:

- implementation dans l'onglet `Tickets`;
- saisie numero ticket;
- saisie code d'acces si requis par backend;
- affichage statut et informations principales;
- actions autorisees pour le client.

Definition of Done:

- un client non authentifie peut retrouver son ticket avec les informations necessaires.

### TICKET-FRONT-004 - Gerer les tickets recents sur cet appareil

Permettre a l'utilisateur de retrouver les tickets crees localement depuis le navigateur ou l'application mobile.

Inclure:

- section `Recents sur cet appareil` dans l'onglet `Tickets`;
- disponible pour utilisateur authentifie ou non;
- stockage local des references utiles: `ticketNumber`, `accessCode` si applicable, `serviceUnitId`, `locationId`, `companyId`, `status`, `createdAt`, `companyName`, `serviceUnitName`, `locationName` lorsque disponibles;
- ouverture rapide d'un ticket recent avec les informations stockees;
- rafraichissement du statut depuis le backend lors de l'ouverture d'un ticket recent;
- option `Vider les tickets recents`;
- message d'aide indiquant que ces tickets sont conserves uniquement dans le navigateur ou l'application mobile du client;
- suppression locale uniquement: vider les recents ne supprime jamais les tickets backend.

Definition of Done:

- un ticket invite cree depuis cet appareil apparait dans `Recents sur cet appareil`;
- un utilisateur peut vider les recents;
- un ticket recent peut etre ouvert sans retaper manuellement le numero et le code;
- le stockage local n'est jamais considere comme une preuve d'identite par le frontend.

### TICKET-FRONT-005 - Limiter les creations invitees avec les tickets recents

Appliquer cote frontend le mode `AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET` pour les visiteurs non authentifies.

Inclure:

- lecture du `ticketCreationGuardMode` expose par l'unite de service;
- si le mode est `AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET`, verifier les tickets recents locaux avant creation invitee;
- bloquer la creation invitee si un ticket recent ouvert existe pour la meme unite de service;
- proposer `Voir le ticket existant` et `J'ai un autre code`;
- autoriser une nouvelle creation si aucun ticket recent ouvert n'existe localement pour cette unite;
- considerer comme ouverts les statuts `CREATED` et `RECEIVED`;
- considerer comme liberateurs les statuts `TREATED`, `CUSTOMER_CONFIRMED`, `CANCELLED` et `CLOSED`;
- ne pas afficher le libelle admin `cet appareil`; utiliser un message utilisateur clair dans le contexte client.

Definition of Done:

- le blocage local invite suit le mode backend expose;
- le comportement reste non bloquant pour les invites si le mode est `NONE`;
- le frontend ne tente pas de garantir un blocage global des visiteurs non authentifies.

### TICKET-FRONT-003 - Actions client sur ticket

Permettre au client d'agir sur son ticket selon le cycle de vie valide.

Inclure:

- annuler;
- confirmer que le ticket a ete traite cote client;
- affichage des actions seulement si elles sont autorisees.

Definition of Done:

- le frontend respecte les transitions backend;
- les actions indisponibles ne sont pas proposees.

## Milestone 5 - Espace Admin Entreprise

Objectif: permettre a un admin de gerer ses entreprises et leur configuration de base.

### COMPANY-FRONT-001 - Lister mes entreprises

Afficher les entreprises de l'utilisateur authentifie.

Inclure:

- integration dans l'espace entreprise;
- bouton `Creer une entreprise`;
- recherche/filtre dans la liste des entreprises si pertinent pour le MVP;
- pagination;
- entreprises actives et desactivees si l'API admin les retourne;
- acces creation/detail/modification;
- clic sur une entreprise vers la page d'administration de cette entreprise.

Definition of Done:

- un admin voit ses entreprises apres connexion.
- l'espace entreprise reste distinct du parcours client public.
- un utilisateur non connecte est invite a se connecter ou creer un compte.

### COMPANY-FRONT-002 - Creer une entreprise

Brancher le formulaire creation entreprise.

Inclure:

- nom requis;
- description optionnelle;
- devise;
- domaine/type;
- adresse optionnelle avec latitude/longitude optionnelles;
- affichage erreurs backend.

Definition of Done:

- un admin peut creer une entreprise depuis le frontend.

### COMPANY-FRONT-003 - Modifier une entreprise

Brancher le formulaire modification entreprise.

Inclure:

- champs entreprise actuels;
- domaine/type;
- adresse;
- devise;
- gestion erreurs.

Definition of Done:

- un admin peut mettre a jour son entreprise.

### CATCAT-FRONT-001 - Gerer les categories de catalogue

Permettre la creation et la consultation des categories.

Inclure:

- liste categories;
- creation categorie;
- etats chargement/vide/erreur.

Definition of Done:

- un admin peut organiser son catalogue par categories.

### CATALOG-FRONT-001 - Gerer les catalogues

Permettre la creation, consultation, modification et archivage des catalogues.

Inclure:

- liste catalogues;
- filtre categorie si disponible;
- prix optionnel;
- modification;
- archivage.

Definition of Done:

- un admin peut gerer les catalogues utilises par ses services.

### SERVICE-FRONT-001 - Gerer les unites de service

Permettre la creation, consultation et modification des unites de service.

Inclure:

- nom;
- description;
- mode de controle de creation de tickets (`ticketCreationGuardMode`) avec les libelles admin:
  `Aucune restriction`, `Clients connectes uniquement, un ticket ouvert maximum`, `Clients connectes controles, invites limites cote application`;
- lien public si expose;
- association catalogue;
- etat actif/archive selon backend.

Definition of Done:

- un admin peut configurer une unite de service.

### LOCATION-FRONT-001 - Gerer les emplacements

Permettre la creation et la consultation des emplacements d'une unite de service.

Inclure:

- emplacement par defaut;
- creation d'emplacements;
- liste emplacements;
- liens de creation ticket.

Definition of Done:

- un admin peut structurer une unite par emplacement.

### ITEM-FRONT-001 - Gerer les articles d'une unite de service

Permettre la creation et consultation des articles.

Inclure:

- liste articles;
- creation article;
- prix issu du catalogue si disponible;
- quantite representative si disponible;
- pas de blocage frontend sur quantite depassee.

Definition of Done:

- un admin peut preparer les articles selectionnables dans les tickets.

### TICKET-ADMIN-FRONT-001 - Lister les tickets d'une unite de service

Afficher les tickets d'une unite de service pour l'admin.

Inclure:

- pagination;
- filtre statut;
- filtre numero ticket;
- filtre emplacement;
- tri si l'API le supporte;
- affichage statut et infos client.

Definition of Done:

- un admin peut suivre les demandes d'une unite de service.

### TICKET-ADMIN-FRONT-002 - Mettre a jour le cycle de vie ticket cote equipe

Permettre a l'equipe de faire avancer un ticket.

Inclure:

- marquer recu;
- traiter;
- annuler;
- respecter les transitions backend;
- afficher confirmation utilisateur.

Definition of Done:

- l'equipe peut gerer le flux de traitement depuis le frontend.

## Milestone 6 - Qualite, Tests et Packaging

Objectif: fiabiliser l'application avant de brancher un deploiement.

### QA-FRONT-001 - Ajouter tests widget de base

Ajouter des tests pour les composants/ecrans principaux.

Inclure:

- app shell;
- formulaires auth;
- affichage erreur;
- composants badges/statuts.

Definition of Done:

- les tests couvrent les parties critiques du socle UI.

### QA-FRONT-002 - Documenter le lancement local frontend

Mettre a jour le README frontend.

Inclure:

- prerequisites;
- commandes Flutter;
- lancement web;
- lancement Android;
- configuration API locale;
- lien Swagger backend.

Definition of Done:

- un developpeur peut lancer le frontend localement depuis le README.

### DEPLOY-FRONT-001 - Preparer build web Docker/Azure

Preparer la future livraison frontend.

Inclure:

- build web Flutter;
- strategie image Docker si necessaire;
- variables d'environnement;
- alignement avec Azure Container Apps;
- documentation dev/prod.

Definition of Done:

- le frontend a une direction de deploiement claire, sans deployer avant validation.

## Ordre Recommande

1. `FRONT-001` + `FRONT-002`
2. `FRONT-003` + `FRONT-004`
3. `FRONT-010` + `FRONT-011` + `FRONT-012`
4. `AUTH-FRONT-001` + `AUTH-FRONT-002`
5. `COMPANY-FRONT-001`
6. `PUBLIC-FRONT-001` + `PUBLIC-FRONT-002`
7. Parcours ticket public et authentifie
8. Espace admin complet
9. Qualite et packaging
