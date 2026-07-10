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

- `Accueil`: entree par defaut de l'application. Elle contient la recherche d'entreprises actives, les filtres publics, l'acces aux fiches entreprises, aux unites de service et a la creation de ticket. Elle expose aussi une action secondaire `Scanner un QR code` pour ouvrir rapidement un lien public d'emplacement ou d'unite de service. Elle ne doit pas contenir le raccourci `Consulter un ticket par code`.
- `Tickets`: espace dedie au suivi des tickets. Il contient `Mes tickets`, reserve aux tickets du compte authentifie, `Tickets recents`, disponible authentifie ou non avec les tickets crees localement dans le navigateur ou l'application mobile du client, ainsi que `Voir un ticket avec le code`, accessible aux utilisateurs authentifies ou non.
- `Entreprise`: espace admin/entreprise. Si l'utilisateur n'est pas connecte, il propose `Se connecter` et `Creer un compte`. Si l'utilisateur est connecte, il contient `Creer une entreprise`, la liste des entreprises de l'utilisateur avec recherche/filtre, puis l'acces a la page d'administration d'une entreprise.
- `Profil`: espace compte sobre. Il affiche l'avatar, l'etat de session et les informations de profil disponibles. Les preferences seront ajoutees plus tard sans dupliquer les raccourcis deja presents dans `Tickets` ou `Entreprise`.

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

### FRONT-006 - Unifier la coquille applicative et la barre de navigation

Issue GitHub: #36.

Unifier la structure applicative pour eviter de repeter une barre de menu differente sur chaque ecran.

Inclure:

- coquille applicative unique pour les ecrans racines;
- barre haute coherente entre les espaces principaux et les pages secondaires;
- variante de barre haute avec bouton retour, titre compact et espacement suffisant;
- logo reduit ou masque sur les sous-pages lorsque le bouton retour est present;
- navigation mobile conservee en bottom navigation;
- navigation large conservee en rail ou structure adaptee tablette/desktop;
- pas de librairie externe obligatoire pour le MVP;
- `go_router` pourra etre evalue plus tard pour les routes imbriquees, deep links et shells avances.

Definition of Done:

- l'utilisateur retrouve une navigation principale uniforme dans l'application;
- les pages secondaires ne collent pas le logo au bouton retour;
- les tests widget couvrent la navigation principale et au moins une page secondaire avec retour.

Decision d'implementation:

- la coquille `FlowMovaNavigationShell` porte la barre haute, le menu mobile, le rail large, les titres compacts et le bouton retour;
- les routes secondaires publiques et tickets passent par la meme coquille en conservant l'onglet principal actif;
- chaque ecran garde la responsabilite de son scroll lorsque son contenu est deja scrollable, afin d'eviter les doubles scrolls;
- les placeholders applicatifs sont rendus comme contenu de shell, sans `Scaffold` local.

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

Issue GitHub: #9.

Brancher la recherche publique d'entreprises.

Inclure:

- implementation dans l'accueil client;
- action secondaire `Scanner un QR code`, sans rendre la recherche dependante du scanner;
- recherche texte;
- filtre type/domaine d'entreprise;
- filtres ville, region, pays;
- pagination;
- affichage fiche entreprise.

Definition of Done:

- un utilisateur peut rechercher les entreprises actives;
- les filtres backend disponibles sont exploites.
- la recherche est le contenu principal de l'accueil client.

### PUBLIC-FRONT-005 - Transformer l'accueil entreprises en flux de decouverte

Issue GitHub: #37.

Rendre l'accueil entreprises plus convivial et plus fluide, proche d'un flux marketplace type Uber Eats ou DoorDash.

Inclure:

- recherche compacte, visible sans dominer tout l'ecran;
- filtres de domaine sous forme de chips horizontaux;
- cartes entreprises plus faciles a parcourir;
- sections ou presentation de flux permettant une navigation naturelle entre les entreprises;
- conservation des filtres ville, region et pays dans une zone secondaire;
- conservation des etats chargement, vide, erreur et pagination;
- action QR code secondaire mais accessible;
- absence du raccourci `Consulter un ticket par code`, qui reste dans l'onglet `Tickets`;
- aucune librairie externe obligatoire pour le MVP.

Definition of Done:

- l'utilisateur peut parcourir les entreprises dans un flux plus naturel;
- la recherche publique branchee sur le backend reste fonctionnelle;
- les tests widget couvrent le nouveau flux d'accueil.

### PUBLIC-FRONT-006 - Affiner le flux d'accueil entreprises

Issue GitHub: #38.

Affiner le flux de decouverte apres revue visuelle.

Inclure:

- premiere tuile d'accueil plus compacte;
- suppression du filtre `Region` dans l'interface d'accueil;
- cartes entreprises plus soignees et plus faciles a parcourir;
- suppression de l'affichage de la devise dans les cartes entreprises;
- conservation des filtres utiles valides: recherche texte, domaine, ville et pays;
- compatibilite avec l'API backend existante.

Definition of Done:

- l'accueil prend moins de place avant le flux d'entreprises;
- les cartes entreprises sont plus lisibles;
- les tests widget restent a jour.

### PUBLIC-FRONT-007 - Afficher l'image entreprise dans le flux d'accueil

Issue GitHub: #39.

Afficher l'image publique d'une entreprise dans les cartes du flux d'accueil lorsque le backend fournit `imageUrl`.

Inclure:

- lecture du champ optionnel `imageUrl` dans le modele frontend entreprise;
- affichage de l'image entreprise dans les cartes du flux;
- fallback visuel par domaine lorsque `imageUrl` est absent ou impossible a charger;
- conservation d'une carte compacte et lisible;
- tests de mapping et de rendu.

Definition of Done:

- une entreprise avec image affiche cette image dans le flux;
- une entreprise sans image garde un fallback propre;
- les tests frontend restent verts.

### QR-FRONT-001 - Scanner ou ouvrir un lien QR code

Ajouter une entree QR code depuis l'accueil client pour acceder rapidement au parcours public d'une unite de service ou d'un emplacement.

Inclure:

- bouton/action secondaire `Scanner un QR code` sur l'accueil;
- sur mobile, preparation du parcours scanner camera quand le package Flutter sera valide;
- sur web, fallback simple par saisie ou collage d'un lien public si la camera n'est pas disponible ou non autorisee;
- ouverture du lien public vers l'ecran `PUBLIC-FRONT-004`;
- gestion des permissions camera, chargement et erreur lorsque le scanner reel sera implemente;
- aucun generation de QR code cote frontend ou backend dans ce ticket;
- ne bloque pas la recherche publique d'entreprises.

Definition of Done:

- un utilisateur voit une entree QR code depuis l'accueil;
- l'entree permet d'aller vers un parcours public existant par scan ou lien manuel selon la plateforme;
- un refus de permission camera n'empeche pas d'utiliser l'application;
- le parcours reste separe de `Voir un ticket avec le code`, qui appartient a l'onglet `Tickets`.

### PUBLIC-FRONT-002 - Consulter la fiche publique entreprise

Issue GitHub: #40.

Afficher le detail public d'une entreprise active.

Inclure:

- navigation depuis une carte du flux d'accueil vers la fiche de l'entreprise selectionnee;
- chargement du detail public via `GET /api/companies/{companyId}`;
- affichage image entreprise, nom, description, domaine, localisation et etat;
- affichage des categories publiques via `GET /api/companies/{companyId}/catalog-categories`;
- affichage des catalogues publics via `GET /api/companies/{companyId}/catalogs`;
- onglets catalogue par categorie avec `Tout` en premier et recherche locale par nom/description;
- affichage des unites de service publiques via `GET /api/companies/{companyId}/service-units`;
- rail horizontal des premiers services disponibles avec action `Voir plus` en fin de liste, preparee pour la liste complete avec recherche;
- etats chargement, vide et erreur;
- actions preparees vers les prochaines etapes: consulter une unite de service et creer une demande/ticket;
- compatibilite mobile et web avec une presentation fluide.

Definition of Done:

- le clic sur une carte d'accueil ouvre une vraie fiche entreprise;
- la fiche entreprise permet de comprendre les services disponibles;
- les catalogues peuvent etre filtres par categorie et recherche;
- les catalogues et unites de service publiques sont affiches lorsque le backend en retourne;
- les tests frontend couvrent le mapping API et la navigation depuis l'accueil.

### PUBLIC-FRONT-008 - Consommer les catalogues publics pagines

Issue GitHub: #42.

Adapter la fiche publique entreprise pour consommer les catalogues publics par page lorsque le backend exposera la pagination.

Dependance backend:

- `CATALOG-060` / `flowmova-backend#102`.

Inclure:

- chargement initial d'une premiere page raisonnable de catalogues;
- envoi de la categorie selectionnee au backend via `catalogCategoryId`;
- envoi de la recherche textuelle au backend;
- chargement progressif ou infinite scroll dans la section catalogue;
- conservation des onglets `Tout` et categories;
- etats chargement, vide et erreur dans la zone catalogue.

Definition of Done:

- la fiche entreprise ne charge plus tous les catalogues d'un coup;
- la recherche et le filtre categorie declenchent une requete serveur;
- l'utilisateur peut charger plus d'articles sans quitter la fiche entreprise;
- les tests couvrent le mapping API pagine et les interactions widget.

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

Issue GitHub: #41.

Brancher la creation de ticket.

Inclure:

- implementation depuis la fiche publique entreprise sous forme de panneau guide court;
- bouton principal `Creer une commande` dans la tuile principale de la fiche entreprise;
- selection du service dans le panneau si plusieurs services ouverts existent;
- auto-selection du service si un seul service ouvert existe;
- chargement du detail service public via `GET /api/companies/{companyId}/service-units/{serviceUnitId}`;
- selection d'une location active, incluant les locations non defaut;
- auto-selection de la location si une seule location active existe;
- affichage des articles disponibles de l'unite de service lorsque le backend en retourne;
- quantite optionnelle par article, avec valeur par defaut a 1 lorsque selectionne;
- implementation dans l'onglet `Tickets` plus tard pour les entrees directes;
- support utilisateur connecte;
- support invite avec `guestName` requis;
- telephone optionnel;
- choix emplacement;
- lignes d'articles avec quantite optionnelle par defaut a 1;
- affichage numero de ticket et code d'acces si applicable;
- recapitulatif de confirmation avec service, emplacement, articles commandes si applicable et rappel de conserver le code d'acces;
- enregistrement local du ticket cree dans `Recents sur cet appareil` si un `accessCode` est retourne ou si les informations minimales sont disponibles;
- application du mode `AUTHENTICATED_OR_GUEST_RECENT_ONE_OPEN_TICKET` pour les visiteurs non authentifies: si un ticket recent ouvert existe deja localement pour la meme unite, proposer d'ouvrir le ticket existant au lieu de recreer.

Definition of Done:

- un client peut creer un ticket depuis la fiche entreprise sans quitter le contexte de l'entreprise;
- le parcours reste court: choix service/location seulement lorsqu'il y a plusieurs options;
- un client peut creer un ticket dans une location non defaut;
- le retour backend est affiche clairement;
- les tickets invites crees depuis le navigateur ou l'application mobile sont conserves dans les recents locaux.

### TICKET-FRONT-006 - Fluidifier la creation de ticket depuis la fiche entreprise

Issue GitHub: #43.

Rendre la creation de ticket plus compacte lorsque l'entreprise expose beaucoup de services, emplacements ou articles.

Inclure:

- modal principale sous forme de resume compact;
- sous-modal avec recherche pour choisir le service;
- sous-modal avec recherche pour choisir l'emplacement du service selectionne;
- sous-modal avec recherche pour selectionner plusieurs articles;
- affichage de l'image des articles lorsque disponible;
- affichage des articles selectionnes dans le resume principal;
- conservation des auto-selections lorsqu'il n'existe qu'un seul choix;
- conservation du formulaire court: nom, telephone optionnel, notes optionnelles.

Definition of Done:

- l'utilisateur ne doit pas parcourir de longues listes dans la modal principale;
- services, emplacements et articles sont recherchables localement;
- les articles selectionnes restent visibles avant la creation;
- les tests widget couvrent le parcours principal et au moins une recherche dans une sous-modal.

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

Issue GitHub: #32.

Permettre a l'utilisateur de retrouver les tickets crees localement depuis le navigateur ou l'application mobile.

Inclure:

- section `Recents sur cet appareil` dans l'onglet `Tickets`;
- disponible pour utilisateur authentifie ou non;
- stockage local des references utiles: `ticketNumber`, `accessCode` si applicable, `serviceUnitId`, `locationId`, `companyId`, `status`, `createdAt`, `companyName`, `serviceUnitName`, `locationName` lorsque disponibles;
- ouverture rapide d'un ticket recent avec les informations stockees;
- rafraichissement du statut depuis le backend lors de l'ouverture d'un ticket recent via `POST /api/tickets/guest-access`;
- option `Vider les tickets recents`;
- message d'aide indiquant que ces tickets sont conserves uniquement dans le navigateur ou l'application mobile du client;
- suppression locale uniquement: vider les recents ne supprime jamais les tickets backend.

Definition of Done:

- un ticket invite cree depuis cet appareil apparait dans `Recents sur cet appareil`;
- un utilisateur peut vider les recents;
- un ticket recent peut etre ouvert sans retaper manuellement le numero et le code;
- le stockage local n'est jamais considere comme une preuve d'identite par le frontend.

### TICKET-FRONT-007 - Dedicacer un ecran aux tickets recents

Issue GitHub: #44.

Eviter d'afficher la liste des tickets recents directement dans l'onglet `Tickets`.

Inclure:

- remplacer la liste directe par une entree `Tickets recents`;
- ouvrir un ecran dedie aux tickets recents locaux;
- conserver l'etat vide, l'action `Vider` et l'ouverture rapide d'un ticket recent dans cet ecran;
- conserver `Voir un ticket avec le code` comme entree separee.

Definition of Done:

- l'onglet `Tickets` affiche des entrees simples;
- les tickets locaux ne sont visibles que dans l'ecran `Tickets recents`;
- les tests widget couvrent l'onglet et l'ecran dedie.

### TICKET-FRONT-008 - Afficher les tickets du profil connecte

Issue GitHub: #50.

Afficher dans l'onglet `Tickets` les tickets rattaches au compte utilisateur connecte.

Inclure:

- remplacement du placeholder `Mes tickets` par un ecran connecte;
- consommation de `GET /api/users/me/tickets` avec pagination initiale;
- affichage des tickets backend du compte connecte;
- etats non connecte, chargement, vide et erreur;
- ouverture d'une fiche ticket connectee depuis la liste;
- actions client connectees lorsque le backend les autorise: annuler, confirmer le traitement.

Definition of Done:

- un utilisateur connecte voit ses tickets backend dans `Mes tickets`;
- un utilisateur non connecte est invite a se connecter ou creer un compte;
- `Mes tickets`, `Tickets recents` et `Voir un ticket avec le code` restent des parcours distincts;
- les tests gateway et widget couvrent le chargement, l'etat non connecte et l'ouverture d'un ticket.

### TICKET-FRONT-009 - Afficher les libelles ticket et limiter les recents invites

Issue GitHub: #51.

Afficher les tickets connectes avec les libelles backend lisibles et reserver les tickets recents locaux au parcours invite.

Inclure:

- consommation des champs enrichis de `TicketResponse`: `companyName`, `serviceUnitName`, `locationName`, `locationDefault`, `itemName`, `itemImageUrl`;
- affichage de l'entreprise puis du service dans la fiche ticket connectee;
- masquage de l'emplacement lorsqu'il s'agit de l'emplacement par defaut;
- affichage des vrais noms d'articles;
- reservation des tickets recents locaux aux tickets invites non connectes;
- conservation uniquement des 5 derniers tickets locaux;
- retrait du bouton `Vider` de l'ecran de tickets recents.

Definition of Done:

- `Mes tickets` affiche des libelles lisibles pour entreprise, service, emplacement et articles;
- les tickets crees avec un compte connecte ne sont pas ajoutes aux recents locaux;
- l'ecran des recents locaux ne propose plus de suppression manuelle globale;
- les tests couvrent les nouveaux champs et la limite des 5 recents.

### TICKET-FRONT-010 - Uniformiser les fiches ticket client

Issue GitHub: #52.

Uniformiser la fiche ticket connectee avec la fiche ticket hors connexion, en utilisant la fiche hors connexion comme reference visuelle.

Inclure:

- reprise de la structure visuelle de la fiche hors connexion pour la fiche ticket connectee;
- conservation des appels backend connectes existants pour annuler et confirmer le traitement;
- affichage des memes blocs: entete ticket, progression, informations, note, articles, actions;
- conservation des confirmations avant action irreversible;
- aucun changement de cycle de vie metier.

Definition of Done:

- les fiches connectee et hors connexion ont la meme presentation;
- la fiche connectee affiche les libelles entreprise, service, emplacement non-defaut et articles dans cette presentation;
- les tests widget couvrent la fiche connectee uniformisee.

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

Issue GitHub: #17.

Afficher les entreprises de l'utilisateur authentifie.

Inclure:

- integration dans l'espace entreprise;
- bouton `Creer une entreprise`;
- recherche/filtre dans la liste des entreprises si pertinent pour le MVP;
- pagination;
- entreprises actives et desactivees si l'API admin les retourne;
- acces creation/detail/modification;
- clic sur une entreprise vers la page d'administration de cette entreprise.

Implementation MVP:

- consommation de `GET /api/users/me/companies`;
- onglet `Entreprise` ouvert directement sur cette liste, sans sas intermediaire;
- action `Nouveau` preparee vers `COMPANY-FRONT-002`;
- recherche locale sur la page courante pour le nom, la ville, le role et les statuts;
- pagination backend avec boutons precedent/suivant;
- ouverture d'une entreprise vers le dashboard admin de l'entreprise, en attendant les ecrans admin detailles.

Definition of Done:

- un admin voit ses entreprises apres connexion.
- l'espace entreprise reste distinct du parcours client public.
- un utilisateur non connecte est invite a se connecter ou creer un compte.

### COMPANY-FRONT-002 - Creer une entreprise

Issue GitHub: #19.

Brancher le formulaire creation entreprise.

Inclure:

- nom requis;
- description optionnelle;
- devise;
- domaine/type;
- adresse optionnelle avec latitude/longitude optionnelles;
- affichage erreurs backend.
- bouton `Nouveau` dans la barre superieure de `Mes entreprises`;
- soumission via `POST /api/companies`;
- ouverture du dashboard de l'entreprise creee lorsque l'API retourne l'identifiant.

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

### COMPANY-FRONT-004 - Afficher et respecter compagnie ouverte ou fermee

Issue GitHub: #46.

Adapter le frontend a la disponibilite operationnelle `OPEN` / `CLOSED` d'une compagnie.

Inclure:

- lire la disponibilite operationnelle exposee par le backend;
- afficher un badge `Ouvert` / `Ferme` sur le flux d'accueil et la fiche entreprise;
- lorsqu'une compagnie est `CLOSED`, masquer ou desactiver la creation de commande depuis la fiche;
- afficher un message clair indiquant que l'entreprise n'accepte pas de commandes pour le moment;
- appliquer la meme regle dans le futur parcours QR.

Definition of Done:

- l'utilisateur voit clairement si la compagnie est fermee;
- aucune action de creation n'est disponible cote frontend quand elle est `CLOSED`;
- les compagnies `OPEN` gardent le comportement actuel.

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

### SERVICE-FRONT-002 - Afficher et respecter les unites QR seulement

Issue GitHub: #45.

Adapter le frontend au mode `QR_ONLY` des unites de service.

Inclure:

- lire le nouveau mode expose par le backend sur les unites de service;
- afficher les unites `QR_ONLY` sur la fiche entreprise;
- desactiver la creation de commande depuis la fiche entreprise pour `QR_ONLY`;
- afficher un message clair, par exemple `Commande disponible uniquement via QR code sur place`;
- autoriser la creation dans le futur parcours QR/emplacement.

Definition of Done:

- l'utilisateur comprend qu'il doit scanner le QR code pour cette unite;
- aucune creation depuis la fiche entreprise n'est proposee pour `QR_ONLY`;
- les unites `PUBLIC_AND_QR` gardent le comportement actuel.

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
