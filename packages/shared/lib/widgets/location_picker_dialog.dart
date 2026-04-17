import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:shared/localization/app_localizations_wrapper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/map_constants.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude, String address) onLocationSelected;

  const LocationPickerDialog({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = MapConstants.defaultLocation;
  String _selectedAddress = '';
  bool _isLoading = false;
  bool _isLoadingAddress = false;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    _updateMarker();
    _getAddressFromCoordinates(_selectedLocation);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarker() {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation,
        draggable: true,
        onDragEnd: (LatLng position) {
          setState(() {
            _selectedLocation = position;
          });
          _getAddressFromCoordinates(position);
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.subLocality,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedAddress = 'Address not found';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar('location_permission_denied'.tr(context), Colors.red);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        _showSnackBar('location_services_disabled'.tr(context), Colors.red);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = newLocation;
      });

      _updateMarker();
      _getAddressFromCoordinates(newLocation);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 16.0),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('failed_get_location'.tr(context).replaceAll('{error}', e.toString()), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _updateMarker();
    _getAddressFromCoordinates(position);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: min(800, MediaQuery.of(context).size.width - 32),
        height: min(700, MediaQuery.of(context).size.height - 64),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Select Location',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0284C7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap on the map or drag the marker to select a location',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Current location button
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_isLoading ? 'Getting Location...' : 'Use Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 15.0,
                    ),
                    onTap: _onMapTap,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selected location info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Coordinates: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Expanded(
                        child: _isLoadingAddress
                            ? const SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64748B)),
                                ),
                              )
                            : Text(
                                _selectedAddress.isNotEmpty ? _selectedAddress : 'Loading address...',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'cancel'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onLocationSelected(
                      _selectedLocation.latitude,
                      _selectedLocation.longitude,
                      _selectedAddress,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'select_location'.tr(context),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

