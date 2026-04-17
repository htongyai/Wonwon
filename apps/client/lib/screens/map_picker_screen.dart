import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/map_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:shared/utils/app_logger.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({Key? key, this.initialLatitude, this.initialLongitude})
    : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;
  BitmapDescriptor? _customMarkerIcon;
  bool _isMapStyleLoaded = false;
  bool _showMap = false;

  

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _createCustomMarkerIcon();

    // Allow a short delay before starting to show the map
    // This gives the map time to initialize properly before being visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showMap = true;
        });
      }
    });

    // Safety timeout to prevent infinite loading
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && !_isMapStyleLoaded) {
        setState(() {
          _isMapStyleLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _createCustomMarkerIcon() async {
    final customMarker = await _createLocationMarker();
    if (!mounted) return;
    setState(() {
      _customMarkerIcon = customMarker;
    });
  }

  Future<BitmapDescriptor> _createLocationMarker() async {
    const size = 40.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromCircle(
        center: const Offset(size / 2, size / 2),
        radius: size / 2,
      ),
    );

    // Green background with white border
    final bgPaint =
        Paint()
          ..color = AppConstants.primaryColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;

    // Draw background circle
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, bgPaint);

    // Draw white border
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // Draw pin dot in center
    final centerDotPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 8, centerDotPaint);

    // End recording and convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      // Fallback to default marker if custom creation fails
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          _selectedLocation = MapConstants.defaultLocation;
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _selectedLocation = MapConstants.defaultLocation;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _selectedLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      _selectedLocation = MapConstants.defaultLocation;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    // Apply the map style immediately, before setting the controller
    controller
        .setMapStyle(MapConstants.mapStyle)
        .then((_) {
          // Set the controller
          _mapController = controller;

          // Then update the state once map style is loaded
          if (mounted) {
            setState(() {
              _isMapStyleLoaded = true;
            });
          }
        })
        .catchError((error) {
          appLog("Error setting map style: $error");
          // Set the controller even if there's an error
          _mapController = controller;

          if (mounted) {
            setState(() {
              _isMapStyleLoaded = true;
            });
          }
        });
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'select_location'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Map - only visible when location is loaded and _showMap is true
          if (!_isLoading && _showMap)
            Visibility(
              visible: _isMapStyleLoaded,
              maintainState: true,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? MapConstants.defaultLocation,
                  zoom: 15.0,
                ),
                markers:
                    _selectedLocation != null
                        ? {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _selectedLocation!,
                            icon:
                                _customMarkerIcon ??
                                BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueGreen,
                                ),
                            draggable: true,
                            onDragEnd: (newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                            },
                          ),
                        }
                        : {},
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
            ),

          // Primary loading indicator - when fetching location
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'splash_getting_location'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Secondary loading overlay - when map style is loading
          if (!_isLoading && (!_isMapStyleLoaded || !_showMap))
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'loading_map'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // My location button - only when map is fully loaded
          if (!_isLoading && _isMapStyleLoaded)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'myLocationButton',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
                elevation: 4,
                onPressed: () async {
                  try {
                    // Check for location permission
                    LocationPermission permission =
                        await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        // Show error message if permission is denied
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('location_permission_denied_short'.tr(context)),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                    }

                    if (permission == LocationPermission.deniedForever) {
                      // Show error message if permission is permanently denied
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'location_permission_permanently_denied'.tr(context),
                              ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    final Position position =
                        await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                        );
                    if (!mounted) return;

                    final newLocation = LatLng(
                      position.latitude,
                      position.longitude,
                    );

                    setState(() {
                      _selectedLocation = newLocation;
                    });

                    // Animate camera to new location
                    if (_mapController != null) {
                      await _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(newLocation, 15.0),
                      );
                    }
                  } catch (e) {
                    // Show error message if location retrieval fails
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'error_getting_location'.tr(context).replaceAll('{error}', e.toString()),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),

          // Location info and confirm button - only when map is fully loaded
          if (!_isLoading && _isMapStyleLoaded && _selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Coordinates display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'selected_location'.tr(context),
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Instructions
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'map_picker_instruction'.tr(context),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _selectedLocation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm Location',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
