# FlowMova Brand Guidelines

## Brand Direction

Direction validee pour le MVP: **Compagnon Client**.

FlowMova doit representer un compagnon simple et rassurant qui fluidifie la relation entre une entreprise et son client. L'application aide l'entreprise a se concentrer sur son secteur d'activite pendant que FlowMova simplifie la demande, le suivi et l'experience cote client.

Mots-cles:

- fluide
- jovial
- accessible
- rassurant
- oriente utilisateur
- relation entreprise-client
- mobile-first
- simple sans etre enfantin

## Logo

Concept valide: **Logo 6 - pont fluide avec point de progression**.

Le logo doit representer le flux entre l'entreprise et le client:

- un pont ou arc fluide;
- un point de progression sur le parcours;
- une sensation de demande accompagnee jusqu'a destination;
- une forme simple, lisible en petit et utilisable comme icone d'application.

Le logo ne doit pas etre un monogramme `F/M` comme concept principal. Les lettres peuvent etre suggerees seulement si cela reste naturel. L'idee prioritaire est le flux entreprise-client.

Usage recommande:

- icone seule pour favicon, app icon, boutons compacts;
- icone + wordmark `FlowMova` pour navigation, ecrans de connexion et documents;
- variante monochrome pour fonds contraints.

## Color Palette

Palette MVP:

| Role | Hex | Usage |
| --- | --- | --- |
| Primary Aqua | `#0EA5A7` | actions principales, logo, liens actifs |
| Leaf Green | `#2BB673` | succes, progression positive, etats traites |
| Soft Apricot | `#FFB86B` | accent chaleureux, point de progression, mise en avant |
| Sky Blue | `#38BDF8` | informations, surfaces legeres, details de flux |
| Ink | `#1F2937` | texte principal |
| Slate | `#64748B` | texte secondaire |
| Cloud | `#F4F7FA` | fond d'application |
| White | `#FFFFFF` | surfaces principales |
| Error | `#EF4444` | erreurs et actions destructives |
| Warning | `#FACC15` | alertes non bloquantes |

Regle d'usage:

- utiliser `Primary Aqua` comme couleur de marque principale;
- utiliser `Soft Apricot` avec moderation pour garder le cote chaleureux;
- reserver `Leaf Green` aux statuts positifs et confirmations;
- eviter les interfaces trop sombres pour le MVP.

## Typography

Typographie de marque recommandee:

- **Nunito Sans Bold** pour le wordmark et les titres de marque.

Typographie UI recommandee:

- **Inter** pour l'interface applicative;
- alternative acceptable: **Nunito Sans** si on veut une interface plus arrondie.

Direction:

- titres lisibles, semi-bold;
- corps de texte sobre et clair;
- pas de police trop decorative;
- pas de style trop corporate ou bancaire.

## UI Style

L'interface doit etre claire, fluide et rassurante.

Principes:

- mobile-first;
- composants arrondis mais sobres;
- hierarchie claire;
- peu d'ombres;
- beaucoup de lisibilite;
- actions principales evidentes;
- statuts faciles a comprendre.

Rayons:

- boutons: `10px` a `12px`;
- champs: `10px`;
- cartes: `12px`;
- badges: pill radius.

## Components

### Buttons

Primary:

- fond `#0EA5A7`;
- texte blanc;
- hover plus fonce;
- utilise pour les actions principales comme `Creer un ticket`.

Secondary:

- fond blanc;
- bordure `#D8E3EA`;
- texte `#1F2937`;
- utilise pour les actions secondaires.

Warm Accent:

- fond `#FFB86B`;
- texte `#1F2937`;
- utilise rarement pour attirer l'attention sans donner une sensation d'erreur.

### Inputs

- fond blanc;
- bordure neutre;
- focus avec `Primary Aqua`;
- messages d'erreur en `#EF4444`;
- labels simples et lisibles.

### Cards

Cartes principales:

- fond blanc;
- bordure `#E5EEF3`;
- rayon `12px`;
- ombre tres subtile ou aucune ombre.

Cartes typiques:

- fiche entreprise;
- carte ticket;
- carte unite de service;
- carte emplacement;
- ligne article.

### Badges

Statuts recommandes:

| Statut | Couleur |
| --- | --- |
| Demande recue | `#38BDF8` |
| En cours | `#FFB86B` |
| Traite | `#2BB673` |
| Annule | `#64748B` |
| Erreur | `#EF4444` |

## Tone

Le ton de FlowMova doit etre clair, utile et humain.

Exemples:

- `Votre demande a bien ete recue.`
- `Nous suivons votre demande.`
- `Votre ticket a ete traite.`
- `Besoin d'ajouter une precision ?`

A eviter:

- langage trop technique cote client;
- ton froid ou administratif;
- humour force;
- messages trop longs.

## Design Tokens Draft

```css
:root {
  --color-primary: #0ea5a7;
  --color-success: #2bb673;
  --color-accent: #ffb86b;
  --color-info: #38bdf8;
  --color-text: #1f2937;
  --color-text-muted: #64748b;
  --color-background: #f4f7fa;
  --color-surface: #ffffff;
  --color-error: #ef4444;
  --color-warning: #facc15;

  --font-brand: "Nunito Sans", system-ui, sans-serif;
  --font-ui: "Inter", system-ui, sans-serif;

  --radius-sm: 8px;
  --radius-md: 10px;
  --radius-lg: 12px;
  --radius-pill: 999px;
}
```

## Open Decisions

- Produire une version SVG finale du logo `Logo 6`.
- Choisir definitivement entre `Inter` et `Nunito Sans` pour toute l'interface.
- Valider les contrastes exacts lors de l'implementation frontend.
- Definir les variantes logo: clair, sombre, monochrome, app icon.
