import '../../data/models/event_report_model.dart';

/// Domain entity for a Traccar event report entry.
class EventReport {
  const EventReport({
    required this.id,
    required this.type,
    required this.eventTime,
    required this.deviceId,
    required this.deviceName,
    this.speedKmh,
    this.positionId,
    this.geofenceId,
    required this.attributes,
  });

  final int id;
  final String type;
  final DateTime eventTime;
  final int deviceId;
  final String deviceName;
  final double? speedKmh;
  final int? positionId;
  final int? geofenceId;
  final Map<String, dynamic> attributes;

  /// Returns a user-friendly French label for the event type.
  String get labelFr => _labels[type] ?? 'Inconnu';

  /// Returns the severity level: 'critical', 'warning', 'info', 'neutral'.
  String get severity => _severities[type] ?? 'neutral';

  static const _labels = <String, String>{
    'deviceOverspeed': 'Excès de vitesse',
    'ignitionOn': 'Démarrage moteur',
    'ignitionOff': 'Arrêt moteur',
    'deviceOnline': 'Appareil en ligne',
    'deviceOffline': 'Appareil hors ligne',
    'geofenceEnter': 'Entrée zone',
    'geofenceExit': 'Sortie zone',
    'alarm': 'Alarme',
    'maintenance': 'Maintenance',
    'deviceMoving': 'En mouvement',
    'deviceStopped': 'Arrêté',
    'deviceUnknown': 'Inconnu',
    'driverChanged': 'Changement conducteur',
    'hardAcceleration': 'Accélération brusque',
    'hardBraking': 'Freinage brusque',
    'hardCornering': 'Virage brusque',
    'queuedCommandSent': 'Commande envoyée',
    'commandResult': 'Résultat commande',
    'deviceFuelDrop': 'Chute carburant',
    'deviceFuelIncrease': 'Hausse carburant',
    'lowBattery': 'Batterie faible',
    'powerOff': 'Coupure alimentation',
    'powerOn': 'Mise en marche',
    'sos': 'Appel SOS',
    'vibration': 'Vibration détectée',
    'tampering': 'Tentative sabotage',
    'textMessage': 'Message texte',
    'driverOnline': 'Conducteur en ligne',
    'driverOffline': 'Conducteur hors ligne',
    'deviceInactive': 'Appareil inactif',
  };

  static const _severities = <String, String>{
    'deviceOverspeed': 'critical',
    'alarm': 'critical',
    'hardBraking': 'critical',
    'hardAcceleration': 'warning',
    'hardCornering': 'warning',
    'geofenceEnter': 'info',
    'geofenceExit': 'warning',
    'ignitionOn': 'success',
    'deviceMoving': 'info',
    'deviceOnline': 'info',
    'deviceOffline': 'neutral',
    'ignitionOff': 'neutral',
    'deviceStopped': 'neutral',
    'maintenance': 'warning',
    'driverChanged': 'info',
    'queuedCommandSent': 'info',
    'commandResult': 'info',
    'deviceFuelDrop': 'warning',
    'deviceFuelIncrease': 'info',
    'lowBattery': 'warning',
    'powerOff': 'critical',
    'powerOn': 'success',
    'sos': 'critical',
    'vibration': 'warning',
    'tampering': 'critical',
    'textMessage': 'info',
    'driverOnline': 'info',
    'driverOffline': 'neutral',
    'deviceInactive': 'neutral',
  };

  static EventReport fromModel(EventReportModel m) => EventReport(
        id: m.id,
        type: m.type,
        eventTime: m.eventTime,
        deviceId: m.deviceId,
        deviceName: m.deviceName,
        speedKmh: m.speedKmh,
        positionId: m.positionId,
        geofenceId: m.geofenceId,
        attributes: m.attributes,
      );
}
