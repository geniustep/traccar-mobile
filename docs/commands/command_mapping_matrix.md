# Command Mapping Matrix — Traccar GPS App

> **Single source of truth** for all commands in the app.  
> Each row maps an internal `appCommandKey` to the Traccar API type, send method, parameters, hardware requirements, roles and offline behavior.  
> **Do not add commands to the catalog without a corresponding row in this table.**

---

## Legend

| Column | Values |
|--------|--------|
| **Method** | `native` · `custom` · `saved` · `unsupported` · `device-specific` |
| **Offline Behavior** | `allow` · `queue` · `block` |
| **Risk** | `Low` · `Medium` · `High` |
| **Category** | Device Information · Tracking · Security & Alerts · Vehicle Control · Maintenance · Advanced |

---

## A — Device Information

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `positionSingle` | Device Information | Low | `positionSingle` | native | — | `{}` | — | viewer+ | Yes | queue | Yes | Standard position request |
| `statusReport` | Device Information | Low | `getDeviceStatus` | native | — | `{}` | — | viewer+ | Yes | queue | No | Full device status |
| `getVersion` | Device Information | Low | `getVersion` | native | — | `{}` | — | operator+ | Yes | queue | No | Firmware version |
| `getFirmwareVersion` | Device Information | Low | `getVersion` | native | — | `{}` | — | technician+ | Yes | queue | No | Alias of getVersion with technician restriction |
| `identification` | Device Information | Low | `identification` | native | — | `{}` | — | technician+ | Yes | queue | No | IMEI / device ID |
| `getIo` | Device Information | Low | `custom` | device-specific | — | `{"data":"getio"}` | — | technician+ | Yes | queue | No | **Teltonika only** |
| `getGps` | Device Information | Low | `custom` | device-specific | — | `{"data":"getgps"}` | — | technician+ | Yes | queue | No | **Teltonika only** |
| `getGsm` | Device Information | Low | `custom` | device-specific | — | `{"data":"getgsm"}` | — | technician+ | Yes | queue | No | **Teltonika only** |
| `getBattery` | Device Information | Low | `getDeviceStatus` | native | — | `{}` | — | viewer+ | Yes | queue | No | Battery level via device status |
| `getSignal` | Device Information | Low | `getModemStatus` | native | — | `{}` | — | technician+ | Yes | queue | No | GSM/cellular signal diagnostics |

---

## B — Tracking

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `positionPeriodic` | Tracking | Medium | `positionPeriodic` | native | `frequency` (sec) | `{"frequency":30}` | — | operator+ | Yes | queue | No | Periodic tracking |
| `positionStop` | Tracking | Medium | `positionStop` | native | — | `{}` | — | operator+ | Yes | queue | No | Stop periodic reporting |
| `setInterval` | Tracking | Medium | `positionPeriodic` | native | `frequency` (sec) | `{"frequency":60}` | — | technician+ | Yes | queue | No | Same as positionPeriodic |
| `setFrequency` | Tracking | Medium | `positionPeriodic` | native | `frequency` (sec) | `{"frequency":30}` | — | technician+ | Yes | queue | No | Alias with different UI label |
| `setUploadInterval` | Tracking | Medium | `positionPeriodic` | native | `frequency` (sec) | `{"frequency":60}` | — | technician+ | Yes | queue | No | Alias for upload interval |
| `movementAlarm` | Tracking | Medium | `custom` | device-specific | — | `{}` | — | operator+ | Yes | queue | No | Protocol-specific; varies by model |
| `setMovementSensitivity` | Tracking | Medium | `custom` | device-specific | `sensitivity` | `{}` | — | technician+ | Yes | queue | No | Protocol-specific sensitivity level |
| `sleepMode` | Tracking | Medium | `mode` | device-specific | — | `{"mode":"sleep"}` | — | technician+ | Yes | queue | No | May cause offline periods; use with care |
| `wakeUp` | Tracking | Low | `positionSingle` | native | — | `{}` | — | operator+ | No | queue | Yes | Wake via SMS or position request |

---

## C — Security & Alerts

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `alarmArm` | Security & Alerts | Medium | `alarmArm` | native | — | `{}` | — | operator+ | Yes | queue | Yes | Arm vehicle alarm |
| `alarmDisarm` | Security & Alerts | Medium | `alarmDisarm` | native | — | `{}` | — | operator+ | Yes | queue | Yes | Disarm vehicle alarm |
| `overSpeedOn` | Security & Alerts | Medium | `alarmSpeed` | native | `speed` (km/h) | `{"speed":120}` | — | operator+ | Yes | queue | No | Enable overspeed alert |
| `overSpeedOff` | Security & Alerts | Medium | `alarmSpeed` | native | — | `{"speed":0}` | — | operator+ | Yes | queue | No | Disable overspeed alert (speed=0) |
| `setOverspeedThreshold` | Security & Alerts | Medium | `alarmSpeed` | native | `speed` (km/h) | `{"speed":120}` | — | technician+ | Yes | queue | No | Set speed threshold |
| `vibrationOn` | Security & Alerts | Medium | `alarmVibration` | native | — | `{}` | — | operator+ | Yes | queue | No | Enable vibration alert |
| `vibrationOff` | Security & Alerts | Medium | `alarmVibration` | native | — | `{"data":"0"}` | — | operator+ | Yes | queue | No | Disable vibration alert |
| `doorAlarmOn` | Security & Alerts | Medium | `alarmDoor` | native | — | `{}` | `hasDoorInput` | operator+ | Yes | queue | No | **Requires door sensor installation** |
| `doorAlarmOff` | Security & Alerts | Medium | `alarmDoor` | native | — | `{"data":"0"}` | `hasDoorInput` | operator+ | Yes | queue | No | **Requires door sensor installation** |
| `setAuthorizedPhone` | Security & Alerts | Medium | `sosNumber` | native | `phone` | `{}` | — | technician+ | Yes | queue | No | Set SOS/authorized phone number |
| `sosEnable` | Security & Alerts | Medium | `sosNumber` | native | — | `{}` | `hasSosButton` | technician+ | Yes | queue | No | **Requires SOS button installation** |
| `sosDisable` | Security & Alerts | Medium | `custom` | device-specific | — | `{}` | `hasSosButton` | technician+ | Yes | queue | No | **Device-specific command text; requires SOS button** |

---

## D — Vehicle Control

> ⚠️ **All commands in this section are HIGH RISK.**  
> - Must be online (no queue).  
> - Require hardware installation check.  
> - Restricted to Technician/Admin roles.  
> - Show double confirmation dialog.

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `engineStop` | Vehicle Control | **High** | `engineStop` | native | — | `{}` | `hasRelay` OR `hasImmobilizer` | technician+ | **Yes (block)** | **block** | No | Cut engine/immobilize |
| `engineResume` | Vehicle Control | **High** | `engineResume` | native | — | `{}` | `hasRelay` OR `hasImmobilizer` | technician+ | **Yes (block)** | **block** | No | Restore engine |
| `outputControl1On` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":1,"data":"1"}` | `hasOutput1` | technician+ | **Yes (block)** | **block** | No | Output 1 ON |
| `outputControl1Off` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":1,"data":"0"}` | `hasOutput1` | technician+ | **Yes (block)** | **block** | No | Output 1 OFF |
| `outputControl2On` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":2,"data":"1"}` | `hasOutput2` | technician+ | **Yes (block)** | **block** | No | Output 2 ON |
| `outputControl2Off` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":2,"data":"0"}` | `hasOutput2` | technician+ | **Yes (block)** | **block** | No | Output 2 OFF |
| `relayOn` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":1,"data":"1"}` | `hasRelay` | technician+ | **Yes (block)** | **block** | No | Relay ON (= Output 1 ON) |
| `relayOff` | Vehicle Control | **High** | `outputControl` | native | — | `{"index":1,"data":"0"}` | `hasRelay` | technician+ | **Yes (block)** | **block** | No | Relay OFF (= Output 1 OFF) |
| `immobilizerOn` | Vehicle Control | **High** | `engineStop` | native | — | `{}` | `hasImmobilizer` | **admin** | **Yes (block)** | **block** | No | Admin only; requires immobilizer |
| `immobilizerOff` | Vehicle Control | **High** | `engineResume` | native | — | `{}` | `hasImmobilizer` | **admin** | **Yes (block)** | **block** | No | Admin only; requires immobilizer |

---

## E — Maintenance

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `rebootDevice` | Maintenance | Medium | `rebootDevice` | native | — | `{}` | — | technician+ | Yes | queue | No | Reboot GPS tracker |
| `clearAlarms` | Maintenance | Medium | `custom` | device-specific | — | `{}` | — | technician+ | Yes | queue | No | Device-specific command text |
| `setTimezone` | Maintenance | Medium | `setTimezone` | native | `timezone` | `{"timezone":"GMT+1"}` | — | technician+ | Yes | queue | No | |
| `setServerAddress` | Maintenance | **High** | `setConnection` | native | `server`, `port` | `{"server":"","port":5055}` | — | **admin** | **Yes (block)** | **block** | No | Will disconnect device |
| `setAPN` | Maintenance | **High** | `configuration` | native | `apn` | `{"apn":"","apnUsername":"","apnPassword":""}` | — | **admin** | **Yes (block)** | **block** | No | Will affect connectivity |
| `factoryReset` | Maintenance | **High** | `custom` | device-specific | — | `{}` | — | **admin** | **Yes (block)** | **block** | No | **Irreversible!** Device-specific command |

---

## F — Advanced

| App Command Key | Category | Risk | Traccar Type | Method | Required Params | Default Attributes | Install Req. | Allowed Roles | Req. Online | Offline Behavior | SMS Fallback | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `custom` | Advanced | **High** | `custom` | native | `data` (text) | `{"data":""}` | — | technician+ | Yes | queue | Yes | Raw text/SMS command |
| `rawCommand` | Advanced | **High** | `custom` | native | `data` (text) | `{"data":""}` | — | **admin** | Yes | queue | Yes | Admin only raw command |
| `rawHex` | Advanced | **High** | `custom` | native | `data` (hex) | `{"data":""}` | — | **admin** | Yes | queue | No | Admin only HEX command |
| `savedCommand` | Advanced | Medium | *(any)* | saved | — | `{}` | — | technician+ | Yes | queue | No | Must be pre-configured in Traccar |

---

## Notes & Constraints

1. **`engineStop` / `engineResume`** and **`immobilizerOn` / `immobilizerOff`** use the same Traccar types. They are shown as separate commands in the UI with different labels and different role requirements.

2. **`relayOn` / `relayOff`** are identical to `outputControl1On` / `outputControl1Off` in the Traccar API. They are shown separately when a relay (not a generic output) is confirmed installed.

3. **device-specific** commands are sent as `type: 'custom'` with `data` containing the model-specific command string. The exact string must be defined in `DeviceProfilesCatalog`.

4. **Installation requirements** are checked against `DeviceInstallationProfile`. If the flag is `false`, the command shows as `notInstalled` with a clear message.

5. **SMS Fallback** is only active when `DeviceInstallationProfile.smsEnabled = true` AND `simPhoneNumber` is not null.

6. **Queue** (`allow`/`queue`) — Traccar queues the command until the device comes online. **High Risk commands must never be queued** — they are blocked when offline.

7. **`setOverspeedThreshold`** requires `speed` param. UI must show an input field when this command is tapped.

8. **`setAuthorizedPhone`** requires `phone` param. UI must show an input field.

9. **`setTimezone`** requires `timezone` param. UI must show a dropdown/text field.

10. **`setServerAddress`** requires both `server` and `port` params. Show a form with both fields. Admin only — double confirmation required.

---

## User Role → Permission Mapping

| Role | Source | Commands accessible |
|---|---|---|
| `viewer` | `UserEntity.readonly = true` | Device Info (viewer+) only |
| `operator` | Default (not admin, not readonly) | Device Info + Tracking + Security & Alerts |
| `technician` | `UserEntity.attributes['appRole'] = 'technician'` | All except High Risk admin-only and Advanced admin-only |
| `admin` | `UserEntity.administrator = true` | Full access |

---

## Installation Flag → Disable Reason Mapping

| Flag | Disable Reason (shown to user) |
|---|---|
| `hasRelay` | Ce commande nécessite un relais installé et câblé au véhicule. |
| `hasImmobilizer` | Ce commande nécessite un immobiliseur installé et câblé. |
| `hasDoorInput` | Ce commande nécessite un capteur de porte installé. |
| `hasSosButton` | Ce commande nécessite un bouton SOS installé. |
| `hasOutput1` | Ce commande nécessite la sortie 1 installée et câblée. |
| `hasOutput2` | Ce commande nécessite la sortie 2 installée et câblée. |
| `hasFuelSensor` | Ce commande nécessite un capteur de carburant installé. |
| `hasTemperatureSensor` | Ce commande nécessite un capteur de température installé. |
