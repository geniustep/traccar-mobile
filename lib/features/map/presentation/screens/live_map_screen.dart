import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../providers/map_provider.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  String _selectedFilter = 'All';

  static const _defaultCenter = CameraPosition(
    target: LatLng(24.7136, 46.6753), // Riyadh
    zoom: 11,
  );

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => ref.invalidate(mapVehiclesProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<VehicleEntity> vehicles) {
    return vehicles.map((v) {
      final status = StatusBadge.fromString(v.status);
      final color = switch (status) {
        VehicleStatus.moving => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen),
        VehicleStatus.stopped => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
        VehicleStatus.idle => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        VehicleStatus.offline => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet),
      };

      return Marker(
        markerId: MarkerId(v.id),
        position: LatLng(v.latitude, v.longitude),
        icon: color,
        infoWindow: InfoWindow(
          title: v.name,
          snippet: '${v.plateNumber} · ${FormatUtils.speed(v.speed)}',
          onTap: () => context.push('/vehicles/${v.id}'),
        ),
        onTap: () {
          ref.read(selectedMapVehicleProvider.notifier).state = v.id;
        },
      );
    }).toSet();
  }

  List<VehicleEntity> _filterVehicles(List<VehicleEntity> vehicles) {
    if (_selectedFilter == 'All') return vehicles;
    return vehicles.where((v) => v.status == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(mapVehiclesProvider);
    final selectedId = ref.watch(selectedMapVehicleProvider);

    return Scaffold(      body: Stack(
        children: [
          vehiclesAsync.when(
            data: (vehicles) {
              final filtered = _filterVehicles(vehicles);
              final markers = _buildMarkers(filtered);

              return GoogleMap(
                initialCameraPosition: _defaultCenter,
                markers: markers,
                onMapCreated: (c) => _mapController = c,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) {
                  ref.read(selectedMapVehicleProvider.notifier).state = null;
                },
                style: _darkMapStyle,
              );
            },
            loading: () => const ColoredBox(
              color: AppColors.background,
              child: LoadingView(message: 'Loading map…'),
            ),
            error: (_, __) => const ColoredBox(
              color: AppColors.background,
              child: Center(
                child: Text(
                  'Unable to load map',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),

          // Top overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFilterRow(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map controls (bottom right)
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: 200,
            child: Column(
              children: [
                _MapControl(
                  icon: Icons.add,
                  onTap: () => _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  ),
                ),
                const SizedBox(height: 4),
                _MapControl(
                  icon: Icons.remove,
                  onTap: () => _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MapControl(
                  icon: Icons.refresh_rounded,
                  onTap: () => ref.invalidate(mapVehiclesProvider),
                ),
              ],
            ),
          ),

          // Bottom vehicle quick info
          if (selectedId != null)
            vehiclesAsync.whenOrNull(
              data: (vehicles) {
                final vehicle = vehicles.where((v) => v.id == selectedId).firstOrNull;
                if (vehicle == null) return null;
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _VehicleBottomSheet(
                    vehicle: vehicle,
                    onClose: () {
                      ref.read(selectedMapVehicleProvider.notifier).state = null;
                    },
                    onDetails: () => context.push('/vehicles/${vehicle.id}'),
                  ),
                );
              },
            ) ?? const SizedBox.shrink(),

          // Vehicle count badge
          vehiclesAsync.whenOrNull(
            data: (vehicles) {
              final online = vehicles.where((v) => !v.isOffline).length;
              return Positioned(
                bottom: 16,
                left: AppSpacing.screenPadding,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$online/${vehicles.length} online',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.map_rounded, color: AppColors.accent, size: 18),
                SizedBox(width: 8),
                Text('Live Fleet Map', style: AppTextStyles.labelLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    const filters = ['All', 'Moving', 'Stopped', 'Idle', 'Offline'];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}

class _VehicleBottomSheet extends StatelessWidget {
  const _VehicleBottomSheet({
    required this.vehicle,
    required this.onClose,
    required this.onDetails,
  });

  final VehicleEntity vehicle;
  final VoidCallback onClose;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vehicle.name, style: AppTextStyles.headlineSmall),
              Text(vehicle.plateNumber, style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  StatusBadge(status: StatusBadge.fromString(vehicle.status)),
                  const SizedBox(width: 8),
                  Text(
                    FormatUtils.speed(vehicle.speed),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              TextButton(
                onPressed: onDetails,
                child: const Text('Details'),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8fa3b1"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#1a2e44"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#162030"}]},
  {"featureType": "road.arterial", "elementType": "geometry", "stylers": [{"color": "#1a2e44"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#00b4d8"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#060d14"}]},
  {"featureType": "poi", "stylers": [{"visibility": "off"}]}
]
''';
