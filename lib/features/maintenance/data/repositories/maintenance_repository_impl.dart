import '../../domain/entities/maintenance_record.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../datasources/maintenance_remote_datasource.dart';
import '../models/maintenance_record_model.dart';

class MaintenanceRepositoryImpl implements MaintenanceRepository {
  MaintenanceRepositoryImpl(this._dataSource);

  final MaintenanceRemoteDataSource _dataSource;

  @override
  Future<List<MaintenanceRecordEntity>> getRecords({
    String? keyword,
    int? deviceId,
  }) async {
    /// يضيِّق بعض الخلفيات المخزونة دون عمود جهاز ظاهرة عبر شبكة نقطة طرفية واحدة؛
    /// نُكمِّل ذلك بالتصفية أين يقتضي الأمر.
    final rows = await _dataSource.fetch(keyword: keyword, deviceId: deviceId);
    final entities = rows.map((m) => m.toEntity()).toList();

    if (deviceId == null) return entities;

    return entities
        .where((e) => e.deviceId == deviceId)
        .toList(growable: false);
  }

  @override
  Future<MaintenanceRecordEntity> createRecord(
    MaintenanceRecordEntity draft,
  ) async {
    if (draft.deviceId <= 0) {
      throw StateError('ينبغي ربط الصيانة بمركبة صالحة.');
    }

    final base = MaintenanceRecordModel(
      id: 0,
      name: draft.name,
      type: draft.traccarType.isEmpty ? 'mileage' : draft.traccarType,
      start: draft.traccarStart,
      period: draft.traccarPeriod <= 0 ? 999999 : draft.traccarPeriod,
      attributes: {},
    ).copyFromEntity(draft);

    final created = await _dataSource.create(base);
    return created.toEntity();
  }

  @override
  Future<MaintenanceRecordEntity> updateRecord(
    MaintenanceRecordEntity record,
  ) async {
    if (record.deviceId <= 0) {
      throw StateError('ينبغي ربط الصيانة بمركبة صالحة.');
    }

    final merged = MaintenanceRecordModel(
      id: record.id,
      name: record.name,
      type: record.traccarType.isEmpty ? 'mileage' : record.traccarType,
      start: record.traccarStart,
      period:
          record.traccarPeriod <= 0 ? 999999 : record.traccarPeriod,
      attributes: const {},
    ).copyFromEntity(record);

    final updated = await _dataSource.update(merged);
    return updated.toEntity();
  }

  @override
  Future<void> deleteRecord(int id) => _dataSource.deleteRecord(id);
}
