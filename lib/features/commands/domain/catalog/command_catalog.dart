import 'package:flutter/material.dart';

import '../../../../core/models/user_role.dart';
import '../entities/device_command.dart';
import '../entities/traccar_command_mapping.dart';

/// Static catalog of all [DeviceCommand] entries grouped by category.
///
/// This is the **single Dart source of truth** for what commands exist.
/// Each command MUST have a corresponding row in `docs/commands/command_mapping_matrix.md`.
///
/// Rules:
/// - Never hard-code command strings inside widgets — always look up via [byKey].
/// - Add new devices in [DeviceProfilesCatalog], not here.
/// - Do not add a command without filling all required mapping fields.
class CommandCatalog {
  CommandCatalog._();

  // ─────────────────────────────────────────────────────────────────────────
  // A. DEVICE INFORMATION
  // ─────────────────────────────────────────────────────────────────────────

  static const positionSingle = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'positionSingle',
      traccarType: 'positionSingle',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {
        UserRole.viewer,
        UserRole.operator,
        UserRole.technician,
        UserRole.admin,
      },
      requiresOnline: true,
      supportsQueue: true,
      supportsSmsFallback: true,
    ),
    labelFr: 'Demander la position',
    labelAr: 'طلب الموقع الحالي',
    descriptionFr: 'Force une mise à jour immédiate de la position GPS.',
    descriptionAr: 'يطلب تحديثاً فورياً للموقع.',
    icon: Icons.my_location_rounded,
  );

  static const statusReport = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'statusReport',
      traccarType: 'getDeviceStatus',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {
        UserRole.viewer,
        UserRole.operator,
        UserRole.technician,
        UserRole.admin,
      },
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Rapport d\'état',
    labelAr: 'تقرير الحالة',
    descriptionFr: 'Demande un rapport complet de l\'état du véhicule.',
    descriptionAr: 'يطلب تقريراً شاملاً عن حالة المركبة.',
    icon: Icons.assessment_rounded,
  );

  static const getVersion = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'getVersion',
      traccarType: 'getVersion',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {
        UserRole.operator,
        UserRole.technician,
        UserRole.admin,
      },
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Version firmware',
    labelAr: 'إصدار الفيرمور',
    descriptionFr: 'Demande la version du firmware du traceur.',
    descriptionAr: 'يطلب إصدار برنامج الجهاز.',
    icon: Icons.info_outline_rounded,
  );

  static const identification = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'identification',
      traccarType: 'identification',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Identification appareil',
    labelAr: 'معرّف الجهاز (IMEI)',
    descriptionFr: 'Demande l\'identifiant unique de l\'appareil (IMEI).',
    descriptionAr: 'يطلب المعرّف الفريد للجهاز.',
    icon: Icons.badge_rounded,
  );

  static const getIo = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'getIo',
      traccarType: 'custom',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.technician, UserRole.admin},
      defaultAttributes: {'data': 'getio'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'État E/S numériques',
    labelAr: 'حالة المداخل/المخارج',
    descriptionFr: 'Lit l\'état de toutes les entrées/sorties digitales (Teltonika).',
    descriptionAr: 'يقرأ حالة المداخل والمخارج الرقمية (Teltonika فقط).',
    icon: Icons.device_hub_rounded,
  );

  static const getGps = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'getGps',
      traccarType: 'custom',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.technician, UserRole.admin},
      defaultAttributes: {'data': 'getgps'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Diagnostic GPS',
    labelAr: 'تشخيص GPS',
    descriptionFr: 'Lit les paramètres GPS (satellites, signal) — Teltonika.',
    descriptionAr: 'يقرأ معاملات GPS (أقمار، إشارة) — Teltonika فقط.',
    icon: Icons.satellite_alt_rounded,
  );

  static const getGsm = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'getGsm',
      traccarType: 'custom',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.technician, UserRole.admin},
      defaultAttributes: {'data': 'getgsm'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Diagnostic GSM',
    labelAr: 'تشخيص GSM',
    descriptionFr: 'Lit les paramètres réseau cellulaire — Teltonika.',
    descriptionAr: 'يقرأ معاملات شبكة الجوال — Teltonika فقط.',
    icon: Icons.signal_cellular_alt_rounded,
  );

  static const getSignal = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'getSignal',
      traccarType: 'getModemStatus',
      category: CommandCategory.deviceInformation,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Niveau de signal',
    labelAr: 'مستوى الإشارة',
    descriptionFr: 'Demande le niveau du signal GSM/cellulaire.',
    descriptionAr: 'يطلب مستوى إشارة الشبكة الخلوية.',
    icon: Icons.network_cell_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // B. TRACKING
  // ─────────────────────────────────────────────────────────────────────────

  static const positionPeriodic = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'positionPeriodic',
      traccarType: 'positionPeriodic',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiredParameters: ['frequency'],
      defaultAttributes: {'frequency': 30},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Suivi périodique',
    labelAr: 'تتبع دوري',
    descriptionFr: 'Active l\'envoi périodique de la position (fréquence en sec.).',
    descriptionAr: 'يفعّل إرسال الموقع بشكل دوري (التردد بالثواني).',
    icon: Icons.repeat_rounded,
  );

  static const positionStop = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'positionStop',
      traccarType: 'positionStop',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Arrêter le suivi périodique',
    labelAr: 'إيقاف التتبع الدوري',
    descriptionFr: 'Désactive l\'envoi périodique automatique de la position.',
    descriptionAr: 'يوقف إرسال الموقع الدوري التلقائي.',
    icon: Icons.stop_circle_outlined,
  );

  static const setInterval = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'setInterval',
      traccarType: 'positionPeriodic',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredParameters: ['frequency'],
      defaultAttributes: {'frequency': 60},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Définir l\'intervalle',
    labelAr: 'تعيين فترة الإرسال',
    descriptionFr: 'Définit l\'intervalle d\'envoi de position (secondes).',
    descriptionAr: 'يحدد فترة إرسال الموقع بالثواني.',
    icon: Icons.timer_rounded,
  );

  static const sleepMode = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'sleepMode',
      traccarType: 'mode',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.technician, UserRole.admin},
      defaultAttributes: {'mode': 'sleep'},
      requiresOnline: true,
      supportsQueue: true,
      warningMessage:
          'Le mode veille peut entraîner des périodes hors ligne. '
          'Assurez-vous que le réveil automatique est configuré.',
    ),
    labelFr: 'Mode veille',
    labelAr: 'وضع السكون',
    descriptionFr: 'Active le mode économie d\'énergie (peut causer des déconnexions).',
    descriptionAr: 'يفعّل وضع توفير الطاقة (قد يسبب انقطاعات).',
    icon: Icons.bedtime_rounded,
  );

  static const wakeUp = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'wakeUp',
      traccarType: 'positionSingle',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.low,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: false,
      supportsQueue: true,
      supportsSmsFallback: true,
    ),
    labelFr: 'Réveiller l\'appareil',
    labelAr: 'إيقاظ الجهاز',
    descriptionFr: 'Envoie une demande de position pour réveiller l\'appareil.',
    descriptionAr: 'يرسل طلب موقع لإيقاظ الجهاز من وضع السكون.',
    icon: Icons.alarm_rounded,
  );

  static const movementAlarm = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'movementAlarm',
      traccarType: 'custom',
      category: CommandCategory.tracking,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Alarme de mouvement',
    labelAr: 'تنبيه الحركة',
    descriptionFr: 'Active l\'alarme de détection de mouvement (dépend du protocole).',
    descriptionAr: 'يفعّل تنبيه الحركة (يعتمد على البروتوكول).',
    icon: Icons.directions_run_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // C. SECURITY & ALERTS
  // ─────────────────────────────────────────────────────────────────────────

  static const alarmArm = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'alarmArm',
      traccarType: 'alarmArm',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
      supportsSmsFallback: true,
    ),
    labelFr: 'Activer l\'alarme',
    labelAr: 'تفعيل المنبّه',
    descriptionFr: 'Active le système d\'alarme du véhicule.',
    descriptionAr: 'يفعّل نظام الإنذار في المركبة.',
    icon: Icons.notifications_active_rounded,
  );

  static const alarmDisarm = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'alarmDisarm',
      traccarType: 'alarmDisarm',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
      supportsSmsFallback: true,
    ),
    labelFr: 'Désactiver l\'alarme',
    labelAr: 'تعطيل المنبّه',
    descriptionFr: 'Désactive le système d\'alarme du véhicule.',
    descriptionAr: 'يوقف نظام الإنذار في المركبة.',
    icon: Icons.notifications_off_rounded,
  );

  static const overSpeedOn = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'overSpeedOn',
      traccarType: 'alarmSpeed',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiredParameters: ['speed'],
      defaultAttributes: {'speed': 120},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Activer alerte vitesse',
    labelAr: 'تفعيل تنبيه التجاوز',
    descriptionFr: 'Active l\'alerte de dépassement de vitesse (seuil en km/h).',
    descriptionAr: 'يفعّل تنبيه تجاوز السرعة (الحد بكم/ساعة).',
    icon: Icons.speed_rounded,
  );

  static const overSpeedOff = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'overSpeedOff',
      traccarType: 'alarmSpeed',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      defaultAttributes: {'speed': 0},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Désactiver alerte vitesse',
    labelAr: 'إلغاء تنبيه التجاوز',
    descriptionFr: 'Désactive l\'alerte de dépassement de vitesse.',
    descriptionAr: 'يلغي تنبيه تجاوز السرعة.',
    icon: Icons.speed_rounded,
  );

  static const vibrationOn = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'vibrationOn',
      traccarType: 'alarmVibration',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Activer alerte vibration',
    labelAr: 'تفعيل تنبيه الاهتزاز',
    descriptionFr: 'Active la détection de vibration/choc.',
    descriptionAr: 'يفعّل كشف الاهتزاز والصدمة.',
    icon: Icons.vibration_rounded,
  );

  static const vibrationOff = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'vibrationOff',
      traccarType: 'alarmVibration',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      defaultAttributes: {'data': '0'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Désactiver alerte vibration',
    labelAr: 'تعطيل تنبيه الاهتزاز',
    descriptionFr: 'Désactive la détection de vibration.',
    descriptionAr: 'يوقف كشف الاهتزاز.',
    icon: Icons.vibration_rounded,
  );

  static const doorAlarmOn = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'doorAlarmOn',
      traccarType: 'alarmDoor',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasDoorInput'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Activer alerte porte',
    labelAr: 'تفعيل تنبيه الباب',
    descriptionFr: 'Active l\'alerte d\'ouverture de porte.',
    descriptionAr: 'يفعّل تنبيه فتح الباب.',
    icon: Icons.sensor_door_rounded,
  );

  static const doorAlarmOff = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'doorAlarmOff',
      traccarType: 'alarmDoor',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.operator, UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasDoorInput'},
      defaultAttributes: {'data': '0'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Désactiver alerte porte',
    labelAr: 'تعطيل تنبيه الباب',
    descriptionFr: 'Désactive l\'alerte d\'ouverture de porte.',
    descriptionAr: 'يوقف تنبيه فتح الباب.',
    icon: Icons.sensor_door_rounded,
  );

  static const setAuthorizedPhone = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'setAuthorizedPhone',
      traccarType: 'sosNumber',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredParameters: ['phone'],
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Définir numéro SOS',
    labelAr: 'تعيين رقم SOS',
    descriptionFr: 'Définit le numéro de téléphone autorisé pour les alertes SOS.',
    descriptionAr: 'يحدد رقم الهاتف المصرّح للتنبيهات.',
    icon: Icons.phone_in_talk_rounded,
  );

  static const sosEnable = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'sosEnable',
      traccarType: 'sosNumber',
      category: CommandCategory.securityAlerts,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasSosButton'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Activer bouton SOS',
    labelAr: 'تفعيل زر SOS',
    descriptionFr: 'Active la fonction bouton SOS.',
    descriptionAr: 'يفعّل وظيفة زر الاستغاثة.',
    icon: Icons.sos_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // D. VEHICLE CONTROL
  // ─────────────────────────────────────────────────────────────────────────

  static const engineStop = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'engineStop',
      traccarType: 'engineStop',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      // hasEngineControl = hasRelay OR hasImmobilizer (virtual flag)
      requiredInstallationFlags: {'hasEngineControl'},
      requiresOnline: true,
      supportsQueue: false,
      requiresSpeedCheck: true,
      maxAllowedSpeedKmh: 10.0,
      warningMessage:
          'Cette action coupe physiquement l\'alimentation du moteur. '
          'N\'exécutez pas cette commande si le véhicule est en mouvement à '
          'grande vitesse.',
    ),
    labelFr: 'Couper le moteur',
    labelAr: 'قطع المحرك',
    descriptionFr:
        'Coupe l\'alimentation moteur via relais ou immobiliseur. '
        'Appareil DOIT être en ligne.',
    descriptionAr:
        'يقطع تغذية المحرك عبر الـ Relay أو Immobilizer. الجهاز يجب أن يكون متصلاً.',
    icon: Icons.power_off_rounded,
  );

  static const engineResume = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'engineResume',
      traccarType: 'engineResume',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      // hasEngineControl = hasRelay OR hasImmobilizer (virtual flag)
      requiredInstallationFlags: {'hasEngineControl'},
      requiresOnline: true,
      supportsQueue: false,
      warningMessage: 'Cette action rétablit l\'alimentation moteur.',
    ),
    labelFr: 'Rétablir le moteur',
    labelAr: 'استعادة المحرك',
    descriptionFr:
        'Rétablit l\'alimentation moteur via relais ou immobiliseur. '
        'Appareil DOIT être en ligne.',
    descriptionAr:
        'يعيد تغذية المحرك عبر الـ Relay أو Immobilizer. الجهاز يجب أن يكون متصلاً.',
    icon: Icons.power_rounded,
  );

  static const outputControl1On = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'outputControl1On',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasOutput1'},
      defaultAttributes: {'index': 1, 'data': '1'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Sortie 1 — Activer',
    labelAr: 'تشغيل Output 1',
    descriptionFr: 'Active la sortie digitale n°1.',
    descriptionAr: 'يشغّل المخرج الرقمي رقم 1.',
    icon: Icons.toggle_on_rounded,
  );

  static const outputControl1Off = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'outputControl1Off',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasOutput1'},
      defaultAttributes: {'index': 1, 'data': '0'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Sortie 1 — Désactiver',
    labelAr: 'إيقاف Output 1',
    descriptionFr: 'Désactive la sortie digitale n°1.',
    descriptionAr: 'يوقف المخرج الرقمي رقم 1.',
    icon: Icons.toggle_off_rounded,
  );

  static const outputControl2On = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'outputControl2On',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasOutput2'},
      defaultAttributes: {'index': 2, 'data': '1'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Sortie 2 — Activer',
    labelAr: 'تشغيل Output 2',
    descriptionFr: 'Active la sortie digitale n°2.',
    descriptionAr: 'يشغّل المخرج الرقمي رقم 2.',
    icon: Icons.toggle_on_rounded,
  );

  static const outputControl2Off = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'outputControl2Off',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasOutput2'},
      defaultAttributes: {'index': 2, 'data': '0'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Sortie 2 — Désactiver',
    labelAr: 'إيقاف Output 2',
    descriptionFr: 'Désactive la sortie digitale n°2.',
    descriptionAr: 'يوقف المخرج الرقمي رقم 2.',
    icon: Icons.toggle_off_rounded,
  );

  static const relayOn = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'relayOn',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasRelay'},
      defaultAttributes: {'index': 1, 'data': '1'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Relais — Activer',
    labelAr: 'تشغيل Relay',
    descriptionFr: 'Active le relais (sortie 1 câblée au relais).',
    descriptionAr: 'يشغّل الـ Relay المتصل بالمخرج 1.',
    icon: Icons.electrical_services_rounded,
  );

  static const relayOff = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'relayOff',
      traccarType: 'outputControl',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredInstallationFlags: {'hasRelay'},
      defaultAttributes: {'index': 1, 'data': '0'},
      requiresOnline: true,
      supportsQueue: false,
    ),
    labelFr: 'Relais — Désactiver',
    labelAr: 'إيقاف Relay',
    descriptionFr: 'Désactive le relais.',
    descriptionAr: 'يوقف الـ Relay.',
    icon: Icons.electrical_services_rounded,
  );

  static const immobilizerOn = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'immobilizerOn',
      traccarType: 'engineStop',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.admin},
      requiredInstallationFlags: {'hasImmobilizer'},
      requiresOnline: true,
      supportsQueue: false,
      requiresSpeedCheck: true,
      maxAllowedSpeedKmh: 5.0,
      warningMessage:
          'Cette commande immobilise le véhicule. '
          'ADMIN uniquement. Ne pas activer si le véhicule est en mouvement.',
    ),
    labelFr: 'Immobiliser le véhicule',
    labelAr: 'تفعيل الإيموبلايزر',
    descriptionFr: 'Active l\'immobiliseur — Admin uniquement.',
    descriptionAr: 'يفعّل الـ Immobilizer — للمدير فقط.',
    icon: Icons.lock_rounded,
  );

  static const immobilizerOff = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'immobilizerOff',
      traccarType: 'engineResume',
      category: CommandCategory.vehicleControl,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.admin},
      requiredInstallationFlags: {'hasImmobilizer'},
      requiresOnline: true,
      supportsQueue: false,
      warningMessage:
          'Cette commande déverrouille l\'immobiliseur — Admin uniquement.',
    ),
    labelFr: 'Désimmobiliser le véhicule',
    labelAr: 'تعطيل الإيموبلايزر',
    descriptionFr: 'Désactive l\'immobiliseur — Admin uniquement.',
    descriptionAr: 'يوقف الـ Immobilizer — للمدير فقط.',
    icon: Icons.lock_open_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // E. MAINTENANCE
  // ─────────────────────────────────────────────────────────────────────────

  static const rebootDevice = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'rebootDevice',
      traccarType: 'rebootDevice',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Redémarrer le traceur',
    labelAr: 'إعادة تشغيل الجهاز',
    descriptionFr: 'Force le redémarrage du traceur GPS.',
    descriptionAr: 'يُجبر جهاز GPS على إعادة التشغيل.',
    icon: Icons.restart_alt_rounded,
  );

  static const clearAlarms = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'clearAlarms',
      traccarType: 'custom',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Effacer les alarmes',
    labelAr: 'مسح التنبيهات',
    descriptionFr: 'Efface les alarmes actives du traceur (dépend du modèle).',
    descriptionAr: 'يمسح التنبيهات النشطة في الجهاز (يعتمد على الموديل).',
    icon: Icons.notification_important_rounded,
  );

  static const setTimezone = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'setTimezone',
      traccarType: 'setTimezone',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredParameters: ['timezone'],
      defaultAttributes: {'timezone': 'GMT+1'},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Définir le fuseau horaire',
    labelAr: 'تعيين المنطقة الزمنية',
    descriptionFr: 'Définit le fuseau horaire du traceur.',
    descriptionAr: 'يحدد المنطقة الزمنية للجهاز.',
    icon: Icons.access_time_rounded,
  );

  static const setServerAddress = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'setServerAddress',
      traccarType: 'setConnection',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.admin},
      requiredParameters: ['server', 'port'],
      defaultAttributes: {'server': '', 'port': 5055},
      requiresOnline: true,
      supportsQueue: false,
      warningMessage:
          'Cette action modifie l\'adresse du serveur. '
          'L\'appareil se déconnectera immédiatement de ce serveur.',
    ),
    labelFr: 'Changer l\'adresse serveur',
    labelAr: 'تغيير عنوان السيرفر',
    descriptionFr: 'Modifie l\'IP/host et le port du serveur Traccar — Admin uniquement.',
    descriptionAr: 'يغيّر عنوان وبورت سيرفر Traccar — للمدير فقط.',
    icon: Icons.dns_rounded,
  );

  static const setAPN = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'setAPN',
      traccarType: 'configuration',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.native,
      allowedRoles: {UserRole.admin},
      requiredParameters: ['apn'],
      defaultAttributes: {'apn': '', 'apnUsername': '', 'apnPassword': ''},
      requiresOnline: true,
      supportsQueue: false,
      warningMessage:
          'Modifier l\'APN peut couper la connexion cellulaire de l\'appareil. '
          'Admin uniquement.',
    ),
    labelFr: 'Modifier les paramètres APN',
    labelAr: 'تعديل إعدادات APN',
    descriptionFr: 'Met à jour les paramètres APN cellulaire — Admin uniquement.',
    descriptionAr: 'يحدّث إعدادات الـ APN — للمدير فقط.',
    icon: Icons.sim_card_rounded,
  );

  static const factoryReset = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'factoryReset',
      traccarType: 'custom',
      category: CommandCategory.maintenance,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.deviceSpecific,
      allowedRoles: {UserRole.admin},
      requiresOnline: true,
      supportsQueue: false,
      warningMessage:
          'IRRÉVERSIBLE ! Cette commande réinitialise le traceur aux '
          'paramètres d\'usine. Toute la configuration sera perdue.',
    ),
    labelFr: 'Réinitialisation usine',
    labelAr: 'إعادة ضبط المصنع',
    descriptionFr: 'Réinitialise le traceur aux paramètres d\'usine — IRRÉVERSIBLE.',
    descriptionAr: 'يعيد الجهاز لإعدادات المصنع — لا يمكن التراجع عنه.',
    icon: Icons.factory_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // F. ADVANCED
  // ─────────────────────────────────────────────────────────────────────────

  static const custom = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'custom',
      traccarType: 'custom',
      category: CommandCategory.advanced,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.custom,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiredParameters: ['data'],
      defaultAttributes: {'data': ''},
      requiresOnline: true,
      supportsQueue: true,
      supportsSmsFallback: true,
    ),
    labelFr: 'Commande personnalisée',
    labelAr: 'أمر مخصص',
    descriptionFr: 'Envoie une commande SMS/GPRS personnalisée (technicien+).',
    descriptionAr: 'يرسل أمراً مخصصاً عبر SMS/GPRS (للتقنيين فقط).',
    icon: Icons.terminal_rounded,
  );

  static const rawCommand = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'rawCommand',
      traccarType: 'custom',
      category: CommandCategory.advanced,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.custom,
      allowedRoles: {UserRole.admin},
      requiredParameters: ['data'],
      defaultAttributes: {'data': ''},
      requiresOnline: true,
      supportsQueue: true,
      supportsSmsFallback: true,
      warningMessage: 'Commande brute — Admin uniquement. Risque de mauvaise configuration.',
    ),
    labelFr: 'Commande brute (texte)',
    labelAr: 'أمر خام (نص)',
    descriptionFr: 'Envoie un texte brut directement au traceur — Admin uniquement.',
    descriptionAr: 'يرسل نصاً خاماً مباشرة للجهاز — للمدير فقط.',
    icon: Icons.code_rounded,
  );

  static const rawHex = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'rawHex',
      traccarType: 'custom',
      category: CommandCategory.advanced,
      riskLevel: CommandRiskLevel.high,
      sendMethod: CommandSendMethod.custom,
      allowedRoles: {UserRole.admin},
      requiredParameters: ['data'],
      defaultAttributes: {'data': ''},
      requiresOnline: true,
      supportsQueue: true,
      warningMessage: 'Commande HEX — Admin uniquement. Risque de mauvaise configuration.',
    ),
    labelFr: 'Commande HEX',
    labelAr: 'أمر HEX',
    descriptionFr: 'Envoie une commande en format hexadécimal — Admin uniquement.',
    descriptionAr: 'يرسل أمراً بصيغة Hex — للمدير فقط.',
    icon: Icons.memory_rounded,
  );

  static const savedCommand = DeviceCommand(
    mapping: TraccarCommandMapping(
      appCommandKey: 'savedCommand',
      traccarType: null,
      category: CommandCategory.advanced,
      riskLevel: CommandRiskLevel.medium,
      sendMethod: CommandSendMethod.saved,
      allowedRoles: {UserRole.technician, UserRole.admin},
      requiresOnline: true,
      supportsQueue: true,
    ),
    labelFr: 'Commande sauvegardée',
    labelAr: 'أمر محفوظ',
    descriptionFr: 'Exécute une commande pré-configurée dans Traccar.',
    descriptionAr: 'ينفّذ أمراً تم إعداده مسبقاً في Traccar.',
    icon: Icons.bookmark_rounded,
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Full catalog
  // ─────────────────────────────────────────────────────────────────────────

  static const List<DeviceCommand> all = [
    // A — Device Information
    positionSingle,
    statusReport,
    getVersion,
    identification,
    getIo,
    getGps,
    getGsm,
    getSignal,
    // B — Tracking
    positionPeriodic,
    positionStop,
    setInterval,
    sleepMode,
    wakeUp,
    movementAlarm,
    // C — Security & Alerts
    alarmArm,
    alarmDisarm,
    overSpeedOn,
    overSpeedOff,
    vibrationOn,
    vibrationOff,
    doorAlarmOn,
    doorAlarmOff,
    setAuthorizedPhone,
    sosEnable,
    // D — Vehicle Control
    engineStop,
    engineResume,
    outputControl1On,
    outputControl1Off,
    outputControl2On,
    outputControl2Off,
    relayOn,
    relayOff,
    immobilizerOn,
    immobilizerOff,
    // E — Maintenance
    rebootDevice,
    clearAlarms,
    setTimezone,
    setServerAddress,
    setAPN,
    factoryReset,
    // F — Advanced
    custom,
    rawCommand,
    rawHex,
    savedCommand,
  ];

  // ── Lookups ───────────────────────────────────────────────────────────────

  static DeviceCommand? byKey(String commandKey) {
    try {
      return all.firstWhere((c) => c.commandKey == commandKey);
    } catch (_) {
      return null;
    }
  }

  static List<DeviceCommand> byCategory(CommandCategory category) =>
      all.where((c) => c.category == category).toList();

  static List<DeviceCommand> forRole(UserRole role) =>
      all.where((c) => c.canBeUsedBy(role)).toList();

  /// Returns Traccar type strings for all commands visible to [role].
  static List<String> allTraccarTypesFor(UserRole role) =>
      forRole(role)
          .map((c) => c.traccarType)
          .whereType<String>()
          .toSet()
          .toList();
}
