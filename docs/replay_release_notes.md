# ELMOGPS — Replay R1–R10 (notes de version internes)

Document de clôture **Phase R10 — Documentation & QA**.  
**Aucune nouvelle fonctionnalité** dans cette phase : consolidation documentaire et validation des tests automatisés.

**Documents liés :**

| Document | Contenu |
|----------|---------|
| [`map_screens_overview.md`](map_screens_overview.md) | Single Replay — sections §12–§18, capteurs §19, Multi §19–§20 |
| [`multi_vehicle_replay.md`](multi_vehicle_replay.md) | Multi Replay complet (D → R10) |

**Écran Single :** `ReplayReportScreen` — `/reports/replay`  
**Écran Multi :** `MultiVehicleReplayScreen` — `/vehicles/replay-multi`

---

## Release Notes par phase

### R1 — Gaps & Missing Data

| | |
|--|--|
| **Ajouté** | Détection gaps GPS (seuil **10 min**), polylines séparées (pas de trait entre fixes), marqueurs gap, `ReplayGapsSheet`, ligne `dataGap` dans la Timeline |
| **Fichiers clés** | `replay_route_gap.dart`, `RoutePolylineBuilder.buildReplaySpeedColoredPolylinesRespectingGaps`, `replay_gaps_sheet.dart` |
| **Limites** | Pas de polyline en pointillés (dashed) ; filtre Timeline gaps = onglet « Tout » + filtre `dataGaps` dédié |

### R2 — Current Point Snapshot Panel

| | |
|--|--|
| **Ajouté** | `ReplaySnapshotPanel` : heure, vitesse, progression %, mouvement, adresse, détails repliables |
| **Fichiers clés** | `replay_point_snapshot.dart`, `replay_snapshot_panel.dart` |
| **Limites** | Snapshot basé sur points de lecture (`ReplayController`, max ~1200) ; pas Multi Replay |

### R3 — Timeline Upgrade

| | |
|--|--|
| **Ajouté** | `routeStart` / `routeEnd`, filtres (arrêts, excès, ignition, dataGaps), résumé une ligne, seek au tap |
| **Fichiers clés** | `replay_timeline_helpers.dart`, `route_event_timeline.dart` |
| **Limites** | Pas de zoom temporel Timeline ; pas de lien bidirectionnel avancé avec le mini graphique |

### R4 — Events Integration

| | |
|--|--|
| **Ajouté** | Événements rapport + alertes période, dédup ±30 s, Timeline `externalEvent`, marqueurs carte (max **20**, GPS requis) |
| **Fichiers clés** | `replay_external_event_mapper.dart`, `replay_event_deduplication.dart`, `replay_external_event_markers.dart` |
| **Limites** | Pas de marqueur sans lat/lon ; pas de geocoding ajouté pour alertes sans position |

### R5 — Motion Smoothness

| | |
|--|--|
| **Ajouté** | Step Next/Previous, glissement visuel marqueur (`replay_motion_helper`), pas d’interpolation Snapshot |
| **Fichiers clés** | `replay_motion_helper.dart`, `replay_controller.dart` (step), `replay_report_screen.dart` |
| **Limites** | Pas de glide à travers un gap ; vitesse max interpolation 220 km/h |

### R6 — Tests & Stability

| | |
|--|--|
| **Ajouté** | Suite tests `test/features/reports/` (controller, gaps, snapshot, timeline, events, motion) ; fix leak `AnimationController` |
| **Limites** | Pas de widget tests `GoogleMap` |

### R7 — Multi Replay Improvements

| | |
|--|--|
| **Ajouté** | fitBounds, auto-follow (throttle ~900 ms), véhicule actif, légende cartes, visibilité, speed colors optionnel, gaps polylines |
| **Fichiers clés** | `multi_vehicle_replay_*`, `multi_vehicle_replay_map_helpers.dart`, `multi_vehicle_replay_polylines.dart` |
| **Limites** | Pas de détection pan manuel pour auto-follow ; pas d’interpolation motion |

### R8 — Comparison KPIs

| | |
|--|--|
| **Ajouté** | `MultiReplayKpiCalculator`, bottom sheet Comparaison, insights (distance, arrêt, vitesse max, etc.) |
| **Fichiers clés** | `multi_replay_kpi.dart`, `multi_replay_comparison_sheet.dart` |
| **Limites** | KPIs estimatifs ; pas « arrivée à destination » ; overspeed seuil interne **80 km/h** |

### R9 — Advanced Sensors & Parameters

| | |
|--|--|
| **Ajouté** | `RoutePoint.attributes?`, mapper capteurs, affichage dans détails Snapshot (max 4 valeurs) |
| **Fichiers clés** | `replay_sensor_snapshot.dart`, `route_datasource.dart` |
| **Limites** | Affichage **Single Replay** uniquement ; pas d’UI capteurs Multi ; pas de valeurs inventées |

### R10 — Documentation & QA

| | |
|--|--|
| **Ajouté** | Ce document, sections consolidées dans `map_screens_overview.md` et `multi_vehicle_replay.md`, checklist QA finale |
| **Limites** | QA terrain reste obligatoire (carte, performances) |

---

## Single Vehicle Replay — référence fonctionnelle

### 1. Source de données

| Élément | Détail |
|---------|--------|
| API | Rapport route existant (`RouteDataSource.getRoute` / `reportRouteProvider`) |
| Modèle | `RoutePoint` (position, speed km/h, course, fixTime, ignition, address?, **attributes?**) |
| Période | `ReportFilterParams` from / to |
| Points complets | Liste route triée — analyse gaps, events, intelligence |
| Points lecture | `ReplayController.loadPoints` — filtre (0,0), tri, échantillon **max 1200** pour play/seek/snapshot |

### 2. Carte

| Élément | Détail |
|---------|--------|
| Polyline | Segments colorés vitesse, **coupés aux gaps** (R1) |
| Marqueurs | Départ / fin / max speed / horaire (zoom) ; gap (violet) ; events externes (max 20) ; véhicule animé |
| Direction | `Marker.rotation` + `flat` si vitesse ≥ 5 km/h et cap valide |
| fitBounds | Au chargement route |
| Auto-follow | `_followVehicle` — désactivé au recentrage manuel / tap Timeline |

### 3. Gaps (R1)

- Seuil : **`replayGapThreshold` = 10 minutes** entre fixes triés.
- Pas de segment polyline entre deux fixes séparés par un gap.
- `ReplayGapsSheet` + badge compteur + `dataGap` Timeline.
- Seek sur gap → premier fix **après** `gapEndTime`.

### 4. Snapshot (R2 + R9)

- Carte fixe : temps, vitesse, % progression, chip mouvement, adresse si serveur.
- Détails (repliables) : coordonnées, cap, ignition (si analyse route le suggère), **capteurs** (fuel, battery, GSM, satellites, accuracy/hdop, driver) **si attributes JSON**.
- Badge « après interruption données » si fix ≈ fin de gap.
- **Aucune valeur fictive** : champs absents = non affichés.

### 5. Timeline (R3 + R4)

Types : `routeStart`, `routeEnd`, `stop`, `overspeed`, `ignitionOn/Off`, `dataGap`, `externalEvent`.  
Filtres + résumé ; tap → seek + caméra + fiche détails (post-frame).

### 6. Events (R4)

- Reports events + alertes période ; fusion avec analyse locale ; dédup **±30 s** même type.
- Carte : GPS obligatoire, budget **20** marqueurs.
- Sans GPS : Timeline + seek sur point route le plus proche.

### 7. Motion (R5)

- `stepNext` / `stepPrevious` (pause + index).
- Glide visuel entre fixes si `canInterpolateBetween` ; sinon saut (gap).
- Snapshot = toujours le **vrai** `currentPoint`.

### 8. Capteurs (R9)

- Clés supportées (si présentes dans `attributes`) : `fuel`*, `power`/battery*, `rssi`/gsm*, `sat`*, `accuracy`/`hdop`, `driverName`/`driver` (texte).
- Whitelist stricte — pas d’affichage JSON brut ni clés inconnues.

---

## Multi Vehicle Replay — référence fonctionnelle

Voir [`multi_vehicle_replay.md`](multi_vehicle_replay.md) sections 1–21.

| Thème | Résumé |
|-------|--------|
| Périmètre | **2–5** véhicules, **un jour**, timeline unifiée |
| Carte | Couleur par véhicule ; speed colors optionnel ; gaps = runs séparés |
| Contrôles | Play/pause, seek, x1–x8, visibilité, labels, **auto-follow**, **recentrer**, chip **Comparaison** |
| Légende | Cartes : nom, vitesse, heure, moving/stopped, actif, masqué |
| KPIs (R8) | Calcul au chargement ; distance Haversine sans gaps ; insights |
| Capteurs | **Non affichés** en UI (R9) |

---

## Commandes de test

```bash
# Single Replay — cœur R1–R6 + R9
flutter test test/features/reports/

# Multi Replay — R7–R8 (+ parsing RoutePoint)
flutter test test/features/vehicles/presentation/replay_multi/

# Timeline / Route intelligence (partagé Replay)
flutter test test/features/map/core/

# Analyse statique (modules Replay)
flutter analyze lib/features/reports/
flutter analyze lib/features/vehicles/presentation/replay_multi/
flutter analyze lib/features/map/data/datasources/route_datasource.dart
```

**Dernière exécution Phase R10 :** les trois suites `flutter test` ci-dessus — **toutes passées** (reports ~105, multi ~52, map/core ~206).

---

## Known limitations (consolidé)

### Single Replay

- Polyline **dashed** non implémentée (segments séparés uniquement).
- Événements sans coordonnées : pas de marqueur carte.
- Capteurs : uniquement si `attributes` dans la réponse route ; driver rare par point.
- `hdop` affiché comme valeur HDOP, pas « mètres GPS ».
- Pas de widget tests carte Google.

### Multi Replay

- Pas d’UI capteurs.
- Pas d’interpolation motion entre fixes.
- Speed colors : plus de polylines avec 5 véhicules.
- Auto-follow ne détecte pas le pan/zoom manuel.
- KPIs : distances et durées **estimatives** ; « première fin de trajet » ≠ arrivée à un lieu.

### KPIs (R8)

- Seuil overspeed **80 km/h** = règle d’analyse interne, pas loi routière.
- `stopsCount` via `RouteEventAnalyzer` (durée min arrêt 4 min, hysteresis vitesse).

### Tests

- QA **appareil réel** requis : caméra, fluidité x8, RTL arabe, bottom sheets.

---

## QA Checklist finale

Cocher manuellement avant validation produit Replay.

### 1. Single Replay — base

- [ ] Aucune donnée route
- [ ] Une seule pointe
- [ ] Trajet normal
- [ ] Trajet long
- [ ] Play / Pause / Restart
- [ ] Slider seek
- [ ] Step Next / Previous (bornes)
- [ ] Vitesses x1, x2, x4, x8

### 2. Gaps

- [ ] Sans gap
- [ ] Un gap
- [ ] Plusieurs gaps
- [ ] Marqueur gap
- [ ] Feuille gaps
- [ ] Filtre dataGaps
- [ ] Pas de mouvement visuel à travers gap

### 3. Snapshot

- [ ] Avec / sans adresse
- [ ] Ignition affichée / masquée (selon analyse)
- [ ] Capteurs présents dans attributes
- [ ] Sans capteurs
- [ ] Attributes inconnues non affichées
- [ ] Replié / déplié

### 4. Timeline

- [ ] routeStart / routeEnd
- [ ] stop / overspeed / ignition
- [ ] dataGap
- [ ] externalEvent
- [ ] Chaque filtre
- [ ] Résumé événements
- [ ] Tap → seek + détails

### 5. Events

- [ ] Événement avec GPS + marqueur
- [ ] Alerte sans GPS (Timeline seulement)
- [ ] Fiche détails
- [ ] Comportement dédup (deux overspeed proches)

### 6. Motion

- [ ] Glide entre deux points proches
- [ ] Saut sur gap
- [ ] Auto-follow on/off
- [ ] Step après play / pause / tap Timeline

### 7. Multi Replay

- [ ] 2 / 3 / 5 véhicules
- [ ] Véhicule sans données
- [ ] Masquer / afficher / tout masquer
- [ ] Véhicule actif
- [ ] Auto-follow
- [ ] Recentrer
- [ ] Speed colors on/off
- [ ] Longs trajets / longueurs différentes

### 8. KPIs

- [ ] Ouvrir Comparaison
- [ ] Distance / durées / vitesses
- [ ] Stops / overspeed
- [ ] Insights
- [ ] Véhicule masqué / actif
- [ ] Trajet avec gaps (pas de distance à travers gap)

### 9. Localisation

- [ ] Français
- [ ] Arabe (+ RTL contrôles)
- [ ] Anglais
- [ ] Espagnol

### 10. Appareil

- [ ] Petit écran
- [ ] Appareil modeste
- [ ] Émulateur Android
- [ ] Appareil Android réel
- [ ] Comportement caméra
- [ ] Performance lecture x8
- [ ] Polylines / marqueurs carte

---

*Phase R10 — Documentation & QA — dernière mise à jour : clôture roadmap Replay R1–R10.*
