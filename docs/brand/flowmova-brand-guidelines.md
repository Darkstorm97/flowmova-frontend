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

Concept valide: **Logo 6 - flux fluide entreprise-client**.

Le logo doit representer le flux entre l'entreprise et le client:

- trois bandes fluides et legerement inclinees;
- un point client a gauche et un point entreprise a droite;
- une sensation de demande accompagnee jusqu'a destination;
- une forme simple, lisible en petit et utilisable comme icone d'application.

Le logo ne doit pas etre un monogramme `F/M` comme concept principal. Les lettres peuvent etre suggerees seulement si cela reste naturel. L'idee prioritaire est le flux entreprise-client.

Usage recommande:

- icone seule pour favicon, app icon, boutons compacts;
- logo complet empile, avec l'icone au-dessus du wordmark `FlowMova`, pour navigation, ecrans de connexion et documents;
- variante monochrome pour fonds contraints.

Assets SVG valides:

| Asset | Fichier | Usage |
| --- | --- | --- |
| Icône seule couleur | [`assets/brand/flowmova-regenerated-logo/flowmova-logo-mark-color-aligned.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-logo-mark-color-aligned.svg) | Source principale du symbole FlowMova. A utiliser pour favicon, boutons compacts, splash screen ou variantes futures. |
| Logo complet couleur | [`assets/brand/flowmova-regenerated-logo/flowmova-logo-with-text-color-aligned.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-logo-with-text-color-aligned.svg) | Version officielle avec le texte `FlowMova` sous l'icône. A utiliser pour navigation, connexion, documents et ecrans de presentation. |
| Icône app couleur | [`assets/brand/flowmova-regenerated-logo/flowmova-app-icon-color.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-app-icon-color.svg) | Version carree pour application, PWA, launcher ou export PNG haute resolution. |
| Icône seule monochrome | [`assets/brand/flowmova-regenerated-logo/flowmova-logo-mark-monochrome.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-logo-mark-monochrome.svg) | Version en une seule couleur pour fonds contraints, documents simples ou impressions. |
| Logo complet monochrome | [`assets/brand/flowmova-regenerated-logo/flowmova-logo-with-text-monochrome.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-logo-with-text-monochrome.svg) | Version officielle avec texte en une seule couleur. A utiliser quand la couleur n'est pas possible ou pas souhaitee. |

Previsualisations PNG:

- [`flowmova-logo-mark-color-aligned.png`](../../assets/brand/flowmova-regenerated-logo/vector-preview/flowmova-logo-mark-color-aligned.png)
- [`flowmova-logo-with-text-color-aligned.png`](../../assets/brand/flowmova-regenerated-logo/vector-preview/flowmova-logo-with-text-color-aligned.png)
- [`flowmova-app-icon-color.png`](../../assets/brand/flowmova-regenerated-logo/vector-preview/flowmova-app-icon-color.png)
- [`flowmova-logo-mark-monochrome.png`](../../assets/brand/flowmova-regenerated-logo/vector-preview/flowmova-logo-mark-monochrome.png)
- [`flowmova-logo-with-text-monochrome.png`](../../assets/brand/flowmova-regenerated-logo/vector-preview/flowmova-logo-with-text-monochrome.png)

Notes de generation:

- Le fichier [`build_logo_variants.py`](../../assets/brand/flowmova-regenerated-logo/build_logo_variants.py) sert a regenerer le logo avec texte, les variantes monochrome et l'icône app depuis l'icône seule validee.
- Les fichiers `*-aligned.svg`, `*-monochrome.svg` et `flowmova-app-icon-color.svg` sont les assets valides pour le MVP. Les anciens essais de generation ne doivent pas etre utilises.

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

Palette exacte du logo valide:

| Element | Couleur |
| --- | --- |
| Vague bleue, debut | `#168AF4` |
| Vague bleue, fin | `#38C3EC` |
| Vague turquoise, debut | `#05A9A7` |
| Vague turquoise, fin | `#37CBD7` |
| Vague verte, debut | `#2FB252` |
| Vague verte, fin | `#8DD93A` |
| Point droit orange, debut | `#FFB347` |
| Point droit orange, fin | `#FF8A1E` |
| Texte logo | `#13233E` |
| Monochrome | `#13233E` |

Pour creer une variante avec d'autres couleurs, partir en priorite de [`flowmova-logo-mark-color-aligned.svg`](../../assets/brand/flowmova-regenerated-logo/flowmova-logo-mark-color-aligned.svg), modifier les gradients SVG dans `<defs>`, puis regenerer les variantes avec [`build_logo_variants.py`](../../assets/brand/flowmova-regenerated-logo/build_logo_variants.py).

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

## Validated Decisions

- Police de marque: `Nunito Sans`.
- Police d'interface: `Inter`.
- Logos MVP valides: couleur avec texte, couleur sans texte, monochrome avec texte, monochrome sans texte, icône app.
- Les contrastes exacts seront verifies pendant l'implementation frontend comme regle de qualite, pas comme decision de direction artistique ouverte.
- La variante sombre n'est pas requise pour le MVP. Elle pourra etre derivee plus tard depuis les SVG valides si le besoin apparait.
