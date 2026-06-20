import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class VehicleMap extends StatefulWidget {
  const VehicleMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.vehicleLatitude,
    this.vehicleLongitude,
  });

  final double latitude;
  final double longitude;
  final double? vehicleLatitude;
  final double? vehicleLongitude;

  @override
  State<VehicleMap> createState() => _VehicleMapState();
}

class _VehicleMapState extends State<VehicleMap> {
  GoogleMapController? _controller;
  bool _cameraInitialized = false;
  late LatLng _position;
  Marker? _marker;

  bool get _hasVehicleMarker =>
      widget.vehicleLatitude != null && widget.vehicleLongitude != null;

  LatLng? get _vehiclePosition {
    if (!_hasVehicleMarker) return null;
    return LatLng(widget.vehicleLatitude!, widget.vehicleLongitude!);
  }

  @override
  void initState() {
    super.initState();
    _position = LatLng(widget.latitude, widget.longitude);
    _marker = _buildVehicleMarker();
  }

  @override
  void didUpdateWidget(covariant VehicleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final vehiclePosition = _vehiclePosition;
    final oldVehiclePosition =
        oldWidget.vehicleLatitude != null && oldWidget.vehicleLongitude != null
        ? LatLng(oldWidget.vehicleLatitude!, oldWidget.vehicleLongitude!)
        : null;

    final cameraTargetChanged =
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude;
    final vehicleMarkerChanged = vehiclePosition != oldVehiclePosition;

    if (cameraTargetChanged) {
      _position = LatLng(widget.latitude, widget.longitude);
    }
    if (vehicleMarkerChanged) {
      _marker = _buildVehicleMarker();
    }

    if (_controller != null && (cameraTargetChanged || vehicleMarkerChanged)) {
      final target = vehiclePosition ?? _position;
      _controller!.animateCamera(CameraUpdate.newLatLngZoom(target, 18));
    }
  }

  Marker? _buildVehicleMarker() {
    final position = _vehiclePosition;
    if (position == null) return null;
    return Marker(
      markerId: const MarkerId('vehicle'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    if (!_cameraInitialized) {
      _cameraInitialized = true;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(_position, 18));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GoogleMap(
        mapType: MapType.satellite,
        myLocationEnabled: !_hasVehicleMarker,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: CameraPosition(target: _position, zoom: 18),
        markers: _marker == null ? {} : {_marker!},
        onMapCreated: _onMapCreated,
      ),
    );
  }
}
