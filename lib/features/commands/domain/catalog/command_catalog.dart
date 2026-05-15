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
    labelEn: 'Request position',
    labelEs: 'Solicitar posición',
    descriptionFr: 'Force une mise à jour immédiate de la position GPS.',
    descriptionAr: 'يطلب تحديثاً فورياً للموقع.',
    descriptionEn: 'Forces an immediate GPS position update.',
    descriptionEs: 'Fuerza una actualización inmediata de la posición GPS.',
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
    labelEn: 'Status report',
    labelEs: 'Informe de estado',
    descriptionFr: 'Demande un rapport complet de l\'état du véhicule.',
    descriptionAr: 'يطلب تقريراً شاملاً عن حالة المركبة.',
    descriptionEn: 'Requests a full vehicle status report.',
    descriptionEs: 'Solicita un informe completo del estado del vehículo.',
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
    labelEn: 'Firmware version',
    labelEs: 'Versión de firmware',
    descriptionFr: 'Demande la version du firmware du traceur.',
    descriptionAr: 'يطلب إصدار برنامج الجهاز.',
    descriptionEn: 'Requests the tracker firmware version.',
    descriptionEs: 'Solicita la versión del firmware del rastreador.',
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
    labelEn: 'Device identification',
    labelEs: 'Identificación del dispositivo',
    descriptionFr: 'Demande l\'identifiant unique de l\'appareil (IMEI).',
    descriptionAr: 'يطلب المعرّف الفريد للجهاز.',
    descriptionEn: 'Requests the unique device identifier (IMEI).',
    descriptionEs: 'Solicita el identificador único del dispositivo (IMEI).',
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
    labelEn: 'I/O status',
    labelEs: 'Estado de E/S',
    descriptionFr: 'Lit l\'état de toutes les entrées/sorties digitales (Teltonika).',
    descriptionAr: 'يقرأ حالة المداخل والمخارج الرقمية (Teltonika فقط).',
    descriptionEn: 'Reads the current state of digital inputs/outputs.',
    descriptionEs: 'Lee el estado actual de las entradas/salidas digitales.',
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
    labelEn: 'GPS data',
    labelEs: 'Datos GPS',
    descriptionFr: 'Lit les paramètres GPS (satellites, signal) — Teltonika.',
    descriptionAr: 'يقرأ معاملات GPS (أقمار، إشارة) — Teltonika فقط.',
    descriptionEn: 'Returns raw GPS signal data and fix quality.',
    descriptionEs: 'Devuelve los datos brutos de señal GPS y calidad de fijación.',
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
    labelEn: 'GSM info',
    labelEs: 'Info GSM',
    descriptionFr: 'Lit les paramètres réseau cellulaire — Teltonika.',
    descriptionAr: 'يقرأ معاملات شبكة الجوال — Teltonika فقط.',
    descriptionEn: 'Returns GSM network and SIM card information.',
    descriptionEs: 'Devuelve información de la red GSM y tarjeta SIM.',
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
    labelEn: 'Signal strength',
    labelEs: 'Intensidad de señal',
    descriptionFr: 'Demande le niveau du signal GSM/cellulaire.',
    descriptionAr: 'يطلب مستوى إشارة الشبكة الخلوية.',
    descriptionEn: 'Checks modem signal quality.',
    descriptionEs: 'Verifica la calidad de señal del módem.',
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
    labelEn: 'Periodic reporting',
    labelEs: 'Reporte periódico',
    descriptionFr: 'Active l\'envoi périodique de la position (fréquence en sec.).',
    descriptionAr: 'يفعّل إرسال الموقع بشكل دوري (التردد بالثواني).',
    descriptionEn: 'Starts periodic position reporting at set intervals.',
    descriptionEs: 'Inicia el reporte periódico de posición a intervalos definidos.',
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
    labelEn: 'Stop reporting',
    labelEs: 'Detener reporte',
    descriptionFr: 'Désactive l\'envoi périodique automatique de la position.',
    descriptionAr: 'يوقف إرسال الموقع الدوري التلقائي.',
    descriptionEn: 'Stops periodic position reporting.',
    descriptionEs: 'Detiene el reporte periódico de posición.',
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
    labelEn: 'Set interval',
    labelEs: 'Configurar intervalo',
    descriptionFr: 'Définit l\'intervalle d\'envoi de position (secondes).',
    descriptionAr: 'يحدد فترة إرسال الموقع بالثواني.',
    descriptionEn: 'Changes the tracking data transmission interval.',
    descriptionEs: 'Cambia el intervalo de transmisión de datos de rastreo.',
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
    labelEn: 'Sleep mode',
    labelEs: 'Modo reposo',
    descriptionFr: 'Active le mode économie d\'énergie (peut causer des déconnexions).',
    descriptionAr: 'يفعّل وضع توفير الطاقة (قد يسبب انقطاعات).',
    descriptionEn: 'Puts the device into power-saving sleep mode.',
    descriptionEs: 'Pone el dispositivo en modo de ahorro de energía.',
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
    labelEn: 'Wake up',
    labelEs: 'Despertar',
    descriptionFr: 'Envoie une demande de position pour réveiller l\'appareil.',
    descriptionAr: 'يرسل طلب موقع لإيقاظ الجهاز من وضع السكون.',
    descriptionEn: 'Wakes the device from sleep mode.',
    descriptionEs: 'Despierta el dispositivo del modo de reposo.',
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
    labelEn: 'Movement alarm',
    labelEs: 'Alarma de movimiento',
    descriptionFr: 'Active l\'alarme de détection de mouvement (dépend du protocole).',
    descriptionAr: 'يفعّل تنبيه الحركة (يعتمد على البروتوكول).',
    descriptionEn: 'Configures the movement detection alarm.',
    descriptionEs: 'Configura la alarma de detección de movimiento.',
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
    labelEn: 'Arm alarm',
    labelEs: 'Activar alarma',
    descriptionFr: 'Active le système d\'alarme du véhicule.',
    descriptionAr: 'يفعّل نظام الإنذار في المركبة.',
    descriptionEn: 'Arms the security alarm system.',
    descriptionEs: 'Activa el sistema de alarma de seguridad.',
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
    labelEn: 'Disarm alarm',
    labelEs: 'Desactivar alarma',
    descriptionFr: 'Désactive le système d\'alarme du véhicule.',
    descriptionAr: 'يوقف نظام الإنذار في المركبة.',
    descriptionEn: 'Disarms the security alarm system.',
    descriptionEs: 'Desactiva el sistema de alarma de seguridad.',
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
    labelEn: 'Enable speed alert',
    labelEs: 'Activar alerta de velocidad',
    descriptionFr: 'Active l\'alerte de dépassement de vitesse (seuil en km/h).',
    descriptionAr: 'يفعّل تنبيه تجاوز السرعة (الحد بكم/ساعة).',
    descriptionEn: 'Enables alerts when the speed limit is exceeded.',
    descriptionEs: 'Activa alertas al exceder el límite de velocidad.',
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
    labelEn: 'Disable speed alert',
    labelEs: 'Desactivar alerta de velocidad',
    descriptionFr: 'Désactive l\'alerte de dépassement de vitesse.',
    descriptionAr: 'يلغي تنبيه تجاوز السرعة.',
    descriptionEn: 'Disables overspeed alerts.',
    descriptionEs: 'Desactiva las alertas de exceso de velocidad.',
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
    labelEn: 'Enable vibration alert',
    labelEs: 'Activar alerta de vibración',
    descriptionFr: 'Active la détection de vibration/choc.',
    descriptionAr: 'يفعّل كشف الاهتزاز والصدمة.',
    descriptionEn: 'Enables vibration detection alert.',
    descriptionEs: 'Activa la alerta de detección de vibración.',
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
    labelEn: 'Disable vibration alert',
    labelEs: 'Desactivar alerta de vibración',
    descriptionFr: 'Désactive la détection de vibration.',
    descriptionAr: 'يوقف كشف الاهتزاز.',
    descriptionEn: 'Disables vibration alert.',
    descriptionEs: 'Desactiva la alerta de vibración.',
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
    labelEn: 'Enable door alert',
    labelEs: 'Activar alerta de puerta',
    descriptionFr: 'Active l\'alerte d\'ouverture de porte.',
    descriptionAr: 'يفعّل تنبيه فتح الباب.',
    descriptionEn: 'Enables alerts when a door is opened.',
    descriptionEs: 'Activa alertas cuando se abre una puerta.',
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
    labelEn: 'Disable door alert',
    labelEs: 'Desactivar alerta de puerta',
    descriptionFr: 'Désactive l\'alerte d\'ouverture de porte.',
    descriptionAr: 'يوقف تنبيه فتح الباب.',
    descriptionEn: 'Disables door open alerts.',
    descriptionEs: 'Desactiva las alertas de apertura de puerta.',
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
    labelEn: 'Set authorized phone',
    labelEs: 'Configurar teléfono autorizado',
    descriptionFr: 'Définit le numéro de téléphone autorisé pour les alertes SOS.',
    descriptionAr: 'يحدد رقم الهاتف المصرّح للتنبيهات.',
    descriptionEn: 'Sets the authorized phone number for SMS commands.',
    descriptionEs: 'Configura el número de teléfono autorizado para comandos SMS.',
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
    labelEn: 'Enable SOS',
    labelEs: 'Activar SOS',
    descriptionFr: 'Active la fonction bouton SOS.',
    descriptionAr: 'يفعّل وظيفة زر الاستغاثة.',
    descriptionEn: 'Enables the SOS emergency button feature.',
    descriptionEs: 'Activa la función del botón de emergencia SOS.',
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
    labelEn: 'Stop engine',
    labelEs: 'Detener motor',
    descriptionFr:
        'Coupe l\'alimentation moteur via relais ou immobiliseur. '
        'Appareil DOIT être en ligne.',
    descriptionAr:
        'يقطع تغذية المحرك عبر الـ Relay أو Immobilizer. الجهاز يجب أن يكون متصلاً.',
    descriptionEn:
        'Cuts the engine fuel supply remotely. Use only when the vehicle is stationary.',
    descriptionEs:
        'Corta el suministro de combustible del motor de forma remota. Usar solo con el vehículo estacionado.',
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
    labelEn: 'Restore engine',
    labelEs: 'Restaurar motor',
    descriptionFr:
        'Rétablit l\'alimentation moteur via relais ou immobiliseur. '
        'Appareil DOIT être en ligne.',
    descriptionAr:
        'يعيد تغذية المحرك عبر الـ Relay أو Immobilizer. الجهاز يجب أن يكون متصلاً.',
    descriptionEn: 'Restores the engine fuel supply.',
    descriptionEs: 'Restaura el suministro de combustible del motor.',
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
    labelEn: 'Output 1 ON',
    labelEs: 'Salida 1 ON',
    descriptionFr: 'Active la sortie digitale n°1.',
    descriptionAr: 'يشغّل المخرج الرقمي رقم 1.',
    descriptionEn: 'Activates digital output relay 1.',
    descriptionEs: 'Activa el relé de salida digital 1.',
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
    labelEn: 'Output 1 OFF',
    labelEs: 'Salida 1 OFF',
    descriptionFr: 'Désactive la sortie digitale n°1.',
    descriptionAr: 'يوقف المخرج الرقمي رقم 1.',
    descriptionEn: 'Deactivates digital output relay 1.',
    descriptionEs: 'Desactiva el relé de salida digital 1.',
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
    labelEn: 'Output 2 ON',
    labelEs: 'Salida 2 ON',
    descriptionFr: 'Active la sortie digitale n°2.',
    descriptionAr: 'يشغّل المخرج الرقمي رقم 2.',
    descriptionEn: 'Activates digital output relay 2.',
    descriptionEs: 'Activa el relé de salida digital 2.',
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
    labelEn: 'Output 2 OFF',
    labelEs: 'Salida 2 OFF',
    descriptionFr: 'Désactive la sortie digitale n°2.',
    descriptionAr: 'يوقف المخرج الرقمي رقم 2.',
    descriptionEn: 'Deactivates digital output relay 2.',
    descriptionEs: 'Desactiva el relé de salida digital 2.',
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
    labelEn: 'Relay ON',
    labelEs: 'Relé ON',
    descriptionFr: 'Active le relais (sortie 1 câblée au relais).',
    descriptionAr: 'يشغّل الـ Relay المتصل بالمخرج 1.',
    descriptionEn: 'Activates the main relay (engine cut).',
    descriptionEs: 'Activa el relé principal (corte de motor).',
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
    labelEn: 'Relay OFF',
    labelEs: 'Relé OFF',
    descriptionFr: 'Désactive le relais.',
    descriptionAr: 'يوقف الـ Relay.',
    descriptionEn: 'Deactivates the main relay (engine restore).',
    descriptionEs: 'Desactiva el relé principal (restaurar motor).',
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
    labelEn: 'Immobilizer ON',
    labelEs: 'Inmovilizador ON',
    descriptionFr: 'Active l\'immobiliseur — Admin uniquement.',
    descriptionAr: 'يفعّل الـ Immobilizer — للمدير فقط.',
    descriptionEn: 'Activates the immobilizer. Vehicle will not start.',
    descriptionEs: 'Activa el inmovilizador. El vehículo no arrancará.',
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
    labelEn: 'Immobilizer OFF',
    labelEs: 'Inmovilizador OFF',
    descriptionFr: 'Désactive l\'immobiliseur — Admin uniquement.',
    descriptionAr: 'يوقف الـ Immobilizer — للمدير فقط.',
    descriptionEn: 'Deactivates the immobilizer.',
    descriptionEs: 'Desactiva el inmovilizador.',
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
    labelEn: 'Reboot device',
    labelEs: 'Reiniciar dispositivo',
    descriptionFr: 'Force le redémarrage du traceur GPS.',
    descriptionAr: 'يُجبر جهاز GPS على إعادة التشغيل.',
    descriptionEn: 'Reboots the tracker device.',
    descriptionEs: 'Reinicia el dispositivo rastreador.',
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
    labelEn: 'Clear alarms',
    labelEs: 'Borrar alarmas',
    descriptionFr: 'Efface les alarmes actives du traceur (dépend du modèle).',
    descriptionAr: 'يمسح التنبيهات النشطة في الجهاز (يعتمد على الموديل).',
    descriptionEn: 'Clears all active alarms on the device.',
    descriptionEs: 'Borra todas las alarmas activas del dispositivo.',
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
    labelEn: 'Set timezone',
    labelEs: 'Configurar zona horaria',
    descriptionFr: 'Définit le fuseau horaire du traceur.',
    descriptionAr: 'يحدد المنطقة الزمنية للجهاز.',
    descriptionEn: 'Sets the device timezone.',
    descriptionEs: 'Configura la zona horaria del dispositivo.',
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
    labelEn: 'Set server address',
    labelEs: 'Configurar dirección del servidor',
    descriptionFr:
        'Modifie l\'IP/host et le port du serveur ELMOGPS — Admin uniquement.',
    descriptionAr: 'يغيّر عنوان الاستضافة وبورت خادوم ELMOGPS — للمدير فقط.',
    descriptionEn:
        'Changes the tracking server address. Incorrect values may disconnect the device.',
    descriptionEs:
        'Cambia la dirección del servidor de rastreo. Valores incorrectos pueden desconectar el dispositivo.',
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
    labelEn: 'Configure APN',
    labelEs: 'Configurar APN',
    descriptionFr: 'Met à jour les paramètres APN cellulaire — Admin uniquement.',
    descriptionAr: 'يحدّث إعدادات الـ APN — للمدير فقط.',
    descriptionEn:
        'Sets the mobile data APN settings. Incorrect values may prevent data connection.',
    descriptionEs:
        'Configura los ajustes APN de datos móviles. Valores incorrectos pueden impedir la conexión de datos.',
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
    labelEn: 'Factory reset',
    labelEs: 'Restablecer de fábrica',
    descriptionFr: 'Réinitialise le traceur aux paramètres d\'usine — IRRÉVERSIBLE.',
    descriptionAr: 'يعيد الجهاز لإعدادات المصنع — لا يمكن التراجع عنه.',
    descriptionEn: 'Resets the device to factory defaults. All settings will be lost.',
    descriptionEs: 'Restablece el dispositivo a los valores de fábrica. Se perderán todos los ajustes.',
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
    labelEn: 'Custom command',
    labelEs: 'Comando personalizado',
    descriptionFr: 'Envoie une commande SMS/GPRS personnalisée (technicien+).',
    descriptionAr: 'يرسل أمراً مخصصاً عبر SMS/GPRS (للتقنيين فقط).',
    descriptionEn: 'Sends a custom text command to the device.',
    descriptionEs: 'Envía un comando de texto personalizado al dispositivo.',
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
    labelEn: 'Raw command',
    labelEs: 'Comando raw',
    descriptionFr: 'Envoie un texte brut directement au traceur — Admin uniquement.',
    descriptionAr: 'يرسل نصاً خاماً مباشرة للجهاز — للمدير فقط.',
    descriptionEn: 'Sends a raw protocol command. For advanced users only.',
    descriptionEs: 'Envía un comando de protocolo sin procesar. Solo para usuarios avanzados.',
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
    labelEn: 'Hex command',
    labelEs: 'Comando hexadecimal',
    descriptionFr: 'Envoie une commande en format hexadécimal — Admin uniquement.',
    descriptionAr: 'يرسل أمراً بصيغة Hex — للمدير فقط.',
    descriptionEn: 'Sends a hexadecimal command. For advanced users only.',
    descriptionEs: 'Envía un comando hexadecimal. Solo para usuarios avanzados.',
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
    labelEn: 'Saved command',
    labelEs: 'Comando guardado',
    descriptionFr:
        'Exécute une commande pré-configurée dans la configuration centrale.',
    descriptionAr: 'ينفّذ أمراً تمّ إعداده مسبقاً في الإعدادات المركزية.',
    descriptionEn: 'Executes a pre-configured command saved on the server.',
    descriptionEs: 'Ejecuta un comando preconfigurado guardado en el servidor.',
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
