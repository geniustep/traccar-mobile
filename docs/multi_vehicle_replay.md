# Replay multi-véhicules — Multi-Vehicle Replay (Phase D)

Documentation officielle pour la Phase D d’ELMOGPS : rejouer les trajets de **2 à 5 véhicules** sur **une même journée**, sur une carte unique avec ligne de temps unifiée.

Module : [`lib/features/vehicles/presentation/replay_multi/`](../lib/features/vehicles/presentation/replay_multi/).

---

## 1. Objectif (Phase D)

Permettre à l’utilisateur de :

- sélectionner **2 à 5 véhicules** ;
- charger les positions GPS de **la journée choisie** (par défaut : aujourd’hui) ;
- visualiser **une polyline par véhicule** (couleurs distinctes) ;
- animer les marqueurs sur une **timeline unifiée** avec contrôles Play / Pause / Reset, curseur et vitesses **x1–x8** ;
- **masquer / afficher** un véhicule depuis une légende compacte.

Hors périmètre Phase D : export PDF/Excel, replay hebdomadaire/mensuel, heatmap, analytics avancés, marqueurs voiture personnalisés, plus de 5 véhicules.

---

## 2. Points d’entrée

| Entrée | Fichier | Condition |
|--------|---------|-----------|
| **Feuille de sélection carte** | [`vehicle_map_filter_sheet.dart`](../lib/features/map/presentation/widgets/vehicle_map_filter_sheet.dart) | `selectedVehicleIds.length` entre **2 et 5** → bouton **« Replay multi-véhicules »** / **« Replay N véhicules »** (`replayMultiVehicles` / `replayVehiclesCount`). Si **> 5** : message `multiReplayLimitMessage` (SnackBar + texte dans la feuille). |
| **Écran comparaison** | [`vehicle_comparison_screen.dart`](../lib/features/vehicles/presentation/screens/vehicle_comparison_screen.dart) | Bouton **« Replay des véhicules comparés »** (`replayComparedVehicles`) si **2–5** véhicules comparés. |
| **Ouverture carte live** | [`live_map_screen.dart`](../lib/features/map/presentation/screens/live_map_screen.dart) | Icône liste (`Icons.checklist_rounded`) dans **`_FleetSummaryBar`** → `showVehicleMapFilterSheet` (tooltip `chooseVehicles`). |

Navigation centralisée : `openMultiVehicleReplay()` dans [`multi_vehicle_replay_screen.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart).

---

## 3. Route GoRouter

| Élément | Valeur |
|---------|--------|
| **Chemin** | `/vehicles/replay-multi` |
| **Déclaration** | [`lib/app/router.dart`](../lib/app/router.dart) (route poussée, hors shell) |
| **Écran** | `MultiVehicleReplayScreen` |

### Arguments de route — `MultiVehicleReplayRouteArgs`

Fichier : [`multi_vehicle_replay_route_args.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_route_args.dart).

```dart
MultiVehicleReplayRouteArgs({
  required List<String> vehicleIds,
  DateTime? date,  // optionnel ; jour civil ; défaut = aujourd’hui
})
```

**`extra` accepté par le routeur :**

- `MultiVehicleReplayRouteArgs` (recommandé) ;
- `Map` avec clés `vehicleIds` (liste) et `date` (`DateTime` optionnel).

Exemple :

```dart
context.push(
  '/vehicles/replay-multi',
  extra: MultiVehicleReplayRouteArgs(
    vehicleIds: ['9', '11', '2'],
    date: DateTime(2026, 5, 15),
  ),
);
```

---

## 4. Limites produit

| Limite | Valeur | Constante / logique |
|--------|--------|-------------------|
| Nombre de véhicules | **2 – 5** | `MultiVehicleReplayLimits.minVehicles` / `maxVehicles` |
| Période | **Un seul jour** | `startOfDay(date)` → `endOfDayForReplay(date)` (fin = maintenant si jour courant) |
| Points par véhicule (carte) | **≤ 900** | `RoutePointDecimator.decimateForMap` — `maxPointsPerVehicle` |
| Pas de timeline playback | **≤ 2000** | `MultiVehicleReplayTimelineBuilder.maxPlaybackTimestamps` |

Sélection invalide :

- **< 2** → `selectAtLeastTwoVehiclesReplay` ;
- **> 5** → `multiReplayLimitMessage`.

---

## 5. Source de données

| Couche | Détail |
|--------|--------|
| **Repository** | `reportsRepositoryProvider` → `ReportsRepository.getRoute` |
| **Provider** | [`multi_vehicle_replay_provider.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_provider.dart) — `multiVehicleReplayLoaderProvider` |
| **Clé** | `MultiVehicleReplayRequest(vehicleIds, date)` |
| **Chargement** | `Future.wait` — une requête route **par véhicule** en parallèle |
| **Plage UTC** | Début du jour sélectionné → fin du jour (ou `DateTime.now()` si aujourd’hui) |

Aucun endpoint dédié « multi-replay » : réutilisation du rapport route existant (même source que le replay simple).

---

## 6. Timeline unifiée

Implémentation : [`multi_vehicle_replay_timeline.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_timeline.dart).

### Construction

1. Pour chaque véhicule : tri des points par `fixTime` (`preparePoints` filtre lat/lng nulles).
2. Collecte de **tous** les `fixTime` uniques dans un `Set`.
3. Tri ascendant → liste `sortedTimes`.
4. **Décimation** de `sortedTimes` si `length > 2000` (`decimateTimestamps`) : conserve **premier** et **dernier**, échantillonnage uniforme entre les deux.
5. Résultat : `MultiVehicleReplayTimeline.timestamps` — pas utilisés pour les polylines, uniquement pour **l’index de lecture** (Play / slider).

Les **points complets** restent dans `pointsByVehicleId` pour le positionnement des marqueurs.

### Lecture pendant le replay

- Le contrôleur avance `currentIndex` sur `timestamps` (tick périodique selon vitesse x1–x8).
- À l’index `i`, `currentTime = timestamps[i]`.
- Pour chaque véhicule : voir §7.

---

## 7. Position du marqueur au temps de replay

Méthode : `MultiVehicleReplayTimeline.pointAtOrBefore(sortedPoints, replayTime)` — **recherche binaire**.

| Situation | Comportement |
|-----------|----------------|
| Aucun point pour le véhicule | Pas de marqueur ; légende **« Aucune donnée de trajet »** |
| `replayTime` **avant** le premier point | Pas de marqueur (véhicule pas encore « démarré ») |
| `replayTime` **≥** un point | Marqueur sur le **dernier point avec `fixTime ≤ replayTime`** |
| Véhicule arrêté d’émettre avant la fin | Dernier point connu reste affiché jusqu’à la fin de la timeline |

`markersAtTime` / `markersAtIndex` agrègent par `vehicleId`.

---

## 8. Gestion des points

| Usage | Jeu de points | Traitement |
|-------|---------------|------------|
| **Timeline + marqueurs** | `MultiVehicleReplayTrack.allPoints` | Points valides triés (complet) |
| **Polylines carte** | `MultiVehicleReplayTrack.mapPoints` | `RoutePointDecimator.decimateForMap` — max **900** pts/véhicule |
| **Pas de lecture** | `timestamps` | Max **2000** horodatages uniques (décimés) |

La décimation des timestamps **ne modifie pas** les positions des marqueurs : elle limite seulement le nombre d’étapes du slider / de la lecture.

---

## 9. Contrôles de replay

Fichiers : [`multi_vehicle_replay_controller.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_controller.dart), barre basse dans [`multi_vehicle_replay_screen.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart).

| Contrôle | Comportement |
|----------|----------------|
| **Play** | Avance `currentIndex` sur la timeline ; tick de base **400 ms** à x1 |
| **Pause** | Arrêt du timer ; marqueurs figés |
| **Reset** | `currentIndex = 0`, pause |
| **Slider** | `seekToProgress(0..1)` → index immédiat, marqueurs mis à jour |
| **Vitesses** | x1, x2, x4, x8 (`PlaybackSpeed` partagé avec replay simple) — intervalle = `400 / multiplier` ms |

Sélecteur de **date** : AppBar — « Aujourd’hui » ou date calendaire (`chooseReplayDate` / `replayToday`). Invalide le loader et réinitialise la session replay.

---

## 10. Légende véhicules

Sous la carte : liste horizontale par véhicule.

| Élément | Détail |
|---------|--------|
| **Pastille couleur** | `MultiVehicleReplayColors.palette` (5 couleurs) |
| **Nom** | Depuis `mapVehiclesProvider`, sinon `vehicleId` |
| **Distance** | Calcul haversine sur `allPoints` si ≥ 2 points |
| **Sans données** | Texte `routeDataUnavailable` ; pas d’icône visibilité |
| **Masquer / afficher** | Tap sur la ligne (si données) → met à jour `visibility` ; **marqueur + polyline** exclus si masqué |

---

## 11. États UI

Enum : `MultiVehicleReplayLoadStatus` dans [`multi_vehicle_replay_state.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_state.dart).

| État | Affichage |
|------|-----------|
| **loading** | `multiReplayLoading` |
| **success** | Carte + légende + contrôles (si au moins un véhicule a des points) |
| **partial data** | Success avec certains véhicules sans route ; les autres fonctionnent |
| **empty** | `multiReplayNoData` (aucun point sur tous les véhicules) |
| **error** | `multiReplayLoadFailed` + bouton **Réessayer** (toutes les requêtes en échec) |
| **invalidSelection** | `< 2` ou `> 5` véhicules — messages dédiés |

---

## 12. Journalisation debug (`AppLogger.replay`)

Canal : [`app_logger.dart`](../lib/core/logging/app_logger.dart) — tag **`[Replay]`**, catégorie performance. Uniquement en **mode debug**.

| Événement | Message (exemple) |
|-----------|-------------------|
| Ouverture | `multi_replay_opened count=N` |
| Début chargement | `multi_replay_load_started count=N date=YYYY-MM-DD` |
| Par véhicule (début) | `multi_replay_vehicle_load_started vehicleId=...` |
| Par véhicule (succès) | `multi_replay_vehicle_load_success vehicleId=... points=N durationMs=...` |
| Par véhicule (échec) | `multi_replay_vehicle_load_failed vehicleId=... error=...` |
| Timeline | `multi_replay_timeline_built vehicles=N timestamps=N durationMs=...` |
| Fin chargement | `multi_replay_load_success count=N totalPoints=N durationMs=...` |
| Échec global | `multi_replay_load_failed error=...` |
| Lecture | `multi_replay_play` / `multi_replay_pause` |
| Vitesse | `multi_replay_speed_changed speed=x2` |
| Visibilité | `multi_replay_vehicle_visibility_changed vehicleId=... visible=true/false` |

Le slider **ne log pas** à chaque mouvement (évite le spam).

---

## 13. Tests unitaires

Fichier : [`test/features/vehicles/presentation/replay_multi/multi_vehicle_replay_test.dart`](../test/features/vehicles/presentation/replay_multi/multi_vehicle_replay_test.dart).

**Résultat : 11/11 passés** (validation 2–5, timeline unifiée, `pointAtOrBefore`, partial data, décimation timestamps, décimation route, visibilité, formatters).

---

## 14. Statut QA appareil (Phase D stabilization)

| Scénario | Statut |
|----------|--------|
| **2 véhicules** | ✅ Testé sur émulateur avec flotte réelle — ex. `load_success count=2`, `totalPoints=4251`, `timestamps=2000`, `durationMs≈4345`, `timeline_built durationMs=23` ; partial data (un véhicule sans points) |
| **3 véhicules** (BOXER, clio, samsung) | ⏳ **Non confirmé** — session d’automatisation UI instable ; validation manuelle courte recommandée |
| **5 véhicules** | ⏳ Non mesuré (flotte de test souvent ≤ 4 véhicules) |
| **x8 (30 s)** | ⏳ Confirmation manuelle finale recommandée |
| **Masquer / afficher** (marker + polyline) | ⏳ Confirmation manuelle finale recommandée ; logique implémentée et couverte par tests unitaires |

Cibles de performance (indicatives) :

- 2 véhicules : acceptable **< 5000 ms** ;
- 3 véhicules : acceptable **< 7000 ms** ;
- 5 véhicules : acceptable **< 10000 ms** ;
- `timeline_built` : idéalement **< 500 ms**.

---

## 15. Limites connues

- **Un jour** seulement — pas de semaine / mois.
- **Maximum 5 véhicules** — pas de replay grande flotte.
- Marqueurs : icônes Google Maps par défaut (pas de silhouette voiture ELMOGPS).
- Timeline décimée à 2000 pas : très dense GPS peut sous-échantillonner les micro-mouvements en lecture (les polylines restent sur points décimés carte).
- Noms véhicules : dépendent du cache `mapVehiclesProvider` au moment du chargement.
- Pas de suivi caméra automatique sur un véhicule pendant le replay.
- QA 3 véhicules / x8 / hide-show : voir §14.

---

## 16. Évolutions futures (hors Phase D)

- Replay multi-jours ou plage personnalisée.
- Marqueurs directionnels / icônes véhicule cohérents avec la carte live.
- Export ou partage de session replay.
- Cache disque des routes du jour pour rechargement instantané.
- Entrée depuis d’autres écrans (rapports, détail véhicule) sans repasser par le picker.
- QA complète 3–5 véhicules documentée avec journaux de performance systématiques.

---

## 17. Fichiers principaux

| Fichier | Rôle |
|---------|------|
| `multi_vehicle_replay_route_args.dart` | Arguments de navigation |
| `multi_vehicle_replay_model.dart` | Limites, couleurs, `MultiVehicleReplayTrack` |
| `multi_vehicle_replay_timeline.dart` | Timeline unifiée + `pointAtOrBefore` |
| `multi_vehicle_replay_formatters.dart` | Validation, formatage temps / distance |
| `multi_vehicle_replay_state.dart` | États de chargement |
| `multi_vehicle_replay_provider.dart` | Chargement parallèle des routes |
| `multi_vehicle_replay_controller.dart` | Lecture (Play, slider, vitesse, visibilité) |
| `multi_vehicle_replay_screen.dart` | UI carte + légende + contrôles |

---

## 18. Phase E — Visual Polish

Phase E améliore l’expérience visuelle **sans modifier** le chargement des données, la timeline unifiée, ni les APIs route.

### Marqueurs

| Mode | Apparence |
|------|-----------|
| **Par défaut** | Icône voiture vue de dessus ([`VehicleMarkerFactory.topDownCarNorthUp`](../lib/features/map/core/vehicle_marker_factory.dart)), teinte = couleur replay du véhicule |
| **Rotation** | Si vitesse ≥ 5 km/h et `course` valide : `Marker.rotation` + `flat: true` |
| **Libellés activés** | Pastille circulaire avec initiales (couleur véhicule) — moins encombrant sur la carte |
| **Échec SVG** | Retour `BitmapDescriptor.defaultMarkerWithHue` par index |

Cache : [`multi_vehicle_replay_marker_icons.dart`](../lib/features/vehicles/presentation/replay_multi/multi_vehicle_replay_marker_icons.dart).

### Légende

- Titre localisé (`replayMapLegend`) + bouton afficher/masquer les libellés carte.
- Pastille = **trait coloré** (ligne 14×3) + nom tronqué.
- Statuts : **Actif** / **Masqué** / **Aucune donnée** (`replayVehicleActive`, `replayVehicleHidden`, `replayVehicleNoData`).
- Véhicule masqué : opacité réduite, bordure atténuée, texte barré, icône œil.
- Sous-titre : distance si calculable, sinon nombre de points (`replayPointsCount`).

### Contrôles bas d’écran

- **Play / Pause** : `FilledButton.tonalIcon` (plus visible).
- **Slider** : heure début | **heure courante** (centre) | heure fin.
- Vitesses x1–x8 : `ChoiceChip` dans `SingleChildScrollView` horizontal (RTL pris en charge).

### Carte

- **Carte temps** (overlay haut) : heure courante, vitesse de lecture, état Lecture / Pause.
- **Recentrer** : bouton overlay — recadre sur les polylines des véhicules **visibles** ; log `replay_recenter`.
- Premier chargement : `fitBounds` une fois ; masquer un véhicule **ne** déclenche pas de recadrage auto.

### États vide / partiel

- Légende : `replayVehicleNoData` pour véhicule sans trajet.
- Écran vide global : `multiReplayNoData` + icône route (pas de valeurs fictives).

### Logs debug (Phase E)

| Événement | Message |
|-----------|---------|
| Recentrage | `replay_recenter` |
| Icônes prêtes | `replay_vehicle_marker_icon_ready count=N` |
| Icône échouée | `replay_vehicle_marker_icon_failed error=...` |
| Libellés | `replay_labels_toggled enabled=true/false` |

Pas de log par mouvement du slider.

### Checklist QA Phase E

- [ ] Replay 2 véhicules — marqueurs colorés distincts
- [ ] Replay 3 véhicules si possible
- [ ] Un véhicule sans données — légende « Aucune donnée »
- [ ] Masquer / afficher — polyline + marqueur + style légende
- [ ] Play / Pause / Reset / slider
- [ ] x1, x2, x4, x8
- [ ] Bouton Recentrer
- [ ] Petit écran — pas de overflow
- [ ] Mise en page arabe (RTL) — vitesses scrollables, légende

### Limites connues (Phase E)

- Libellés carte = initiales en pastille (pas de texte complet flottant sur la carte).
- Rotation désactivée à basse vitesse ou en mode libellés.
- Recentrer manuel si la vue est perdue après zoom manuel.

---

*Dernière mise à jour : Phase E — polish visuel (marqueurs, légende, contrôles, overlay, recentrage).*
