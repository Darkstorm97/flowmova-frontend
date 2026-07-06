# Project Workflow

Cette page formalise les regles de travail du depot frontend FlowMova.

Issue de reference: [DOC-FRONT-001](https://github.com/Darkstorm97/flowmova-frontend/issues/35).

## Sources de verite

Le frontend doit rester aligne avec:

- le scope FS-001 valide;
- les API backend exposees;
- le backlog frontend MVP;
- les decisions de marque dans `docs/brand/flowmova-brand-guidelines.md`.

## Regle avant developpement

Aucune fonctionnalite, evolution d'ecran ou dette technique planifiee ne doit etre implementee sans:

- discussion ou validation du besoin;
- verification de la documentation projet existante;
- creation ou identification d'une issue GitHub;
- mise a jour de la documentation avant ou avec le developpement si le comportement, les ecrans, la navigation, les assets ou le lancement local changent.

## Nomenclature des issues

Les issues doivent suivre la forme:

```text
CODE-000 - Titre en francais
```

Exemples frontend valides:

- `FRONT-003 - Configurer navigation et routes MVP`
- `AUTH-FRONT-002 - Creer l'ecran de connexion`
- `PUBLIC-FRONT-001 - Rechercher et lister les entreprises actives`
- `DOC-FRONT-001 - Documenter les regles projet et la nomenclature des issues`

Le code doit venir du backlog frontend ou d'une famille deja utilisee dans le depot. Si aucun code n'existe encore, creer le prochain code coherent avec le domaine concerne avant de developper.

## Documentation attendue

Pour une nouvelle fonctionnalite ou une evolution visible:

- ajouter ou mettre a jour l'entree de backlog concernee;
- documenter les decisions d'ecran, de navigation ou d'integration API si necessaire;
- mettre a jour les guidelines de marque, README ou docs de lancement local lorsque les assets, la configuration ou le workflow changent.

## Validation, commit et push

Avant commit:

- executer `flutter analyze` et les tests pertinents;
- verifier que le changement reste aligne avec l'issue et la documentation;
- garder les commits scopes et lisibles.

Apres un commit valide:

- pousser immediatement la branche vers le depot distant;
- garder local et distant synchronises.
