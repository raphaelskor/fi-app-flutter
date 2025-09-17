import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/controllers/client_location_controller.dart';
import '../../core/models/client.dart';
import '../../core/models/client_location.dart';
import '../../core/models/client_address.dart';
import '../../core/models/operational_area.dart';
import '../../core/utils/timezone_utils.dart';
import '../../core/services/location_service.dart';
import '../../widgets/common_widgets.dart';

class ClientLocationHistoryScreen extends StatefulWidget {
  final Client client;

  const ClientLocationHistoryScreen({
    Key? key,
    required this.client,
  }) : super(key: key);

  @override
  State<ClientLocationHistoryScreen> createState() =>
      _ClientLocationHistoryScreenState();
}

class _ClientLocationHistoryScreenState
    extends State<ClientLocationHistoryScreen> {
  late ClientLocationController _controller;
  final MapController _mapController = MapController();
  bool _showLocationList = false;

  // User location
  Position? _userPosition;
  bool _isLoadingUserLocation = false;

  @override
  void initState() {
    super.initState();
    _controller = ClientLocationController();

    // Initialize with skorUserId from client
    final skorUserId = widget.client.skorUserId;
    if (skorUserId != null && skorUserId.isNotEmpty) {
      _controller.initialize(
        skorUserId,
        clientId: widget.client.id,
        clientName: widget.client.name,
        clientPhone: widget.client.phone,
      );
      _getCurrentLocation();

      // Auto-focus to delivery address after data loads
      _controller.addListener(_handleDataLoaded);
    } else {
      // Set error using the controller's public method
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.clearError();
        // We'll handle this in the UI by showing appropriate message
      });
    }
  }

  void _handleDataLoaded() {
    if (_controller.loadingState == ClientLocationLoadingState.loaded &&
        !_showLocationList) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOnDeliveryAddress();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingUserLocation = true;
    });

    try {
      _userPosition = await LocationService.getCurrentLocation();
      setState(() {
        _isLoadingUserLocation = false;
      });
      debugPrint(
          '📍 User location: ${_userPosition?.latitude}, ${_userPosition?.longitude}');
    } catch (e) {
      setState(() {
        _isLoadingUserLocation = false;
      });
      debugPrint('❌ Error getting user location: $e');
    }
  }

  void _focusOnDeliveryAddress() {
    final deliveryAddresses =
        _controller.addresses.where((a) => a.isDeliveryAddress).toList();
    if (deliveryAddresses.isNotEmpty) {
      final deliveryAddress = deliveryAddresses.first;
      _mapController.move(
        LatLng(deliveryAddress.latitude, deliveryAddress.longitude),
        15.0, // Zoom closer to delivery address
      );
      debugPrint(
          '🎯 Auto-focused on delivery address: ${deliveryAddress.addressLine1}');
    }
  }

  void _focusOnUserLocation() {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0, // Zoom closer to user location
      );
      debugPrint('🎯 Auto-focused on user location');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDataLoaded);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.client.name} - Location History'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            Consumer<ClientLocationController>(
              builder: (context, controller, child) {
                if (controller.hasData) {
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(_showLocationList ? Icons.map : Icons.list),
                        tooltip: _showLocationList ? 'Show Map' : 'Show List',
                        onPressed: () {
                          setState(() {
                            _showLocationList = !_showLocationList;
                          });
                        },
                      ),
                      if (!_showLocationList) // Only show on map view
                        Consumer<ClientLocationController>(
                          builder: (context, controller, child) {
                            return IconButton(
                              icon: Icon(
                                controller.showOperationalAreas
                                    ? Icons.layers
                                    : Icons.layers_outlined,
                                color: controller.showOperationalAreas
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              tooltip: controller.showOperationalAreas
                                  ? 'Hide Areas (${controller.operationalAreas.length})'
                                  : 'Show Areas (${controller.operationalAreas.length})',
                              onPressed: () {
                                print(
                                    '🔄 Toggling operational areas: ${!controller.showOperationalAreas}');
                                controller.toggleOperationalAreas();
                              },
                            );
                          },
                        ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            IconButton(
              icon: _isLoadingUserLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location),
              onPressed: _isLoadingUserLocation
                  ? null
                  : () async {
                      await _getCurrentLocation();
                      _focusOnUserLocation();
                    },
              tooltip: 'Get My Location',
            ),
            Consumer<ClientLocationController>(
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      controller.isLoading ? null : () => controller.refresh(),
                );
              },
            ),
          ],
        ),
        body: Consumer<ClientLocationController>(
          builder: (context, controller, child) {
            return _buildContent(controller);
          },
        ),
      ),
    );
  }

  Widget _buildContent(ClientLocationController controller) {
    switch (controller.loadingState) {
      case ClientLocationLoadingState.initial:
      case ClientLocationLoadingState.loading:
        return const LoadingWidget(message: 'Loading location history...');

      case ClientLocationLoadingState.error:
        return AppErrorWidget(
          message: controller.errorMessage ?? 'Failed to load location history',
          onRetry: () => controller.refresh(),
        );

      case ClientLocationLoadingState.loaded:
        if (controller.locations.isEmpty && controller.addresses.isEmpty) {
          return _buildEmptyState();
        }
        return _showLocationList
            ? _buildLocationList(controller.locations, controller.addresses)
            : _buildMap(controller.locations, controller.addresses,
                controller.operationalAreas, controller.showOperationalAreas);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Location Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No location history or address data found for this client',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
      List<ClientLocation> locations,
      List<ClientAddress> addresses,
      List<OperationalArea> operationalAreas,
      bool showOperationalAreas) {
    // Combine all locations (location history + addresses) for bounds calculation
    List<LatLng> allPoints = [];

    // Add location history points
    allPoints.addAll(locations.map((l) => LatLng(l.latitude, l.longitude)));

    // Add address points
    allPoints.addAll(addresses.map((a) => LatLng(a.latitude, a.longitude)));

    if (allPoints.isEmpty) {
      return _buildEmptyState();
    }

    // Calculate bounds to fit all markers
    double minLat =
        allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    // Center of all locations
    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${locations.length} location records • ${addresses.length} addresses',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              if (operationalAreas.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      showOperationalAreas
                          ? Icons.layers
                          : Icons.layers_outlined,
                      color: showOperationalAreas ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Operational Areas: ${operationalAreas.length} loaded ${showOperationalAreas ? '(visible)' : '(hidden)'}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            showOperationalAreas ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Cache status indicator
              const SizedBox(height: 4),
              Consumer<ClientLocationController>(
                builder: (context, controller, child) {
                  return Row(
                    children: [
                      Icon(
                        controller.isDataFromCache
                            ? Icons.cached
                            : Icons.cloud_download,
                        color: controller.isDataFromCache
                            ? Colors.green
                            : Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isDataFromCache
                            ? 'Data from cache'
                            : 'Fresh data from server',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.isDataFromCache
                              ? Colors.green
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (addresses.isNotEmpty || operationalAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      if (_userPosition != null)
                        _buildLegendItem(
                            Icons.person_pin, 'My Location', Colors.blue),
                      if (_userPosition != null && addresses.isNotEmpty)
                        const SizedBox(width: 8),
                      if (addresses.any((a) => a.isHomeAddress))
                        _buildLegendItem(Icons.home, 'Home', Colors.green),
                      if (addresses.any((a) => a.isHomeAddress) &&
                          addresses.any((a) => a.isOfficeAddress))
                        const SizedBox(width: 8),
                      if (addresses.any((a) => a.isOfficeAddress))
                        _buildLegendItem(
                            Icons.business, 'Office', Colors.indigo),
                      if (addresses.any((a) => a.isOfficeAddress) &&
                          addresses.any((a) => a.isDeliveryAddress))
                        const SizedBox(width: 8),
                      if (addresses.any((a) => a.isDeliveryAddress))
                        _buildLegendItem(
                            Icons.local_shipping, 'Delivery', Colors.purple),
                      if (addresses.any((a) => a.isDeliveryAddress) &&
                          showOperationalAreas &&
                          operationalAreas.isNotEmpty)
                        const SizedBox(width: 8),
                      if (showOperationalAreas && operationalAreas.isNotEmpty)
                        _buildLegendItem(
                            Icons.layers,
                            'Areas (${operationalAreas.length})',
                            Colors.orange),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(centerLat, centerLng),
              zoom: 10.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skorcard.field_investigator_app',
              ),
              // Operational areas polygons (show first, so they appear behind markers)
              if (showOperationalAreas && operationalAreas.isNotEmpty) ...[
                PolygonLayer(
                  polygons: () {
                    final polygons =
                        _buildOperationalAreaPolygons(operationalAreas);
                    print('🎨 Rendering ${polygons.length} polygons on map');
                    return polygons;
                  }(),
                ),
              ],
              // Polylines for location history (show before markers)
              PolylineLayer(
                polylines: [
                  if (locations.isNotEmpty)
                    Polyline(
                      points: locations
                          .map((l) => LatLng(l.latitude, l.longitude))
                          .toList(),
                      strokeWidth: 2.0,
                      color: Colors.blue.withOpacity(0.6),
                    ),
                ],
              ),
              // Markers on top
              MarkerLayer(
                markers: [
                  // User location marker (if available)
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_pin,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ..._buildLocationMarkers(locations),
                  ..._buildAddressMarkers(addresses),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Polygon> _buildOperationalAreaPolygons(List<OperationalArea> areas) {
    List<Polygon> polygons = [];

    print('🗺️ Building polygons for ${areas.length} operational areas');

    // Use consistent orange color for all operational areas for better visibility
    final Color operationalColor = Colors.orange;

    for (final area in areas) {
      final color = operationalColor;
      print(
          '📍 Processing area: ${area.name} (${area.province}) with ${area.polygons.length} polygons');

      for (int i = 0; i < area.polygons.length; i++) {
        final polygonPoints = area.polygons[i];
        if (polygonPoints.isNotEmpty) {
          print('   └─ Polygon $i: ${polygonPoints.length} points');
          polygons.add(
            Polygon(
              points: polygonPoints,
              color: color.withOpacity(0.25), // More visible fill
              borderColor: color.withOpacity(1.0), // Solid border
              borderStrokeWidth: 3.0, // Thick border for visibility
              isFilled: true, // Ensure fill is applied
              label: area.name,
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ],
              ),
              labelPlacement: PolygonLabelPlacement.centroid,
            ),
          );
        } else {
          print('   └─ Empty polygon detected for ${area.name}');
        }
      }
    }

    print('✅ Total polygons created: ${polygons.length}');
    return polygons;
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildLocationMarkers(List<ClientLocation> locations) {
    return locations.asMap().entries.map((entry) {
      int index = entry.key;
      ClientLocation location = entry.value;

      return Marker(
        point: LatLng(location.latitude, location.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showLocationDetails(location, index + 1),
          child: Container(
            decoration: BoxDecoration(
              color: index == 0
                  ? Colors.green
                  : (index == locations.length - 1 ? Colors.red : Colors.blue),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildAddressMarkers(List<ClientAddress> addresses) {
    return addresses.map((address) {
      IconData icon;
      Color color;

      if (address.isHomeAddress) {
        icon = Icons.home;
        color = Colors.green;
      } else if (address.isOfficeAddress) {
        icon = Icons.business;
        color =
            Colors.indigo; // Changed from orange to indigo for better contrast
      } else {
        icon = Icons.location_on;
        color = Colors.grey;
      }

      return Marker(
        point: LatLng(address.latitude, address.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showAddressDetails(address),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: address.isDeliveryAddress ? Colors.purple : Colors.white,
                width: address.isDeliveryAddress ? 3 : 2,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLocationList(
      List<ClientLocation> locations, List<ClientAddress> addresses) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.list, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${locations.length} location records • ${addresses.length} addresses',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Show addresses first
              if (addresses.isNotEmpty) ...[
                Text(
                  'Registered Addresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...addresses.asMap().entries.map((entry) {
                  return _buildAddressCard(entry.value);
                }),
                const SizedBox(height: 24),
              ],

              // Show location history
              if (locations.isNotEmpty) ...[
                Text(
                  'Location History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...locations.asMap().entries.map((entry) {
                  final location = entry.value;
                  final number = entry.key + 1;
                  return _buildLocationCard(location, number);
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(ClientLocation location, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: number == 1
                        ? Colors.green
                        : (number == _controller.locations.length
                            ? Colors.red
                            : Colors.blue),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${TimezoneUtils.formatIndonesianDate(location.timestamp)} ${TimezoneUtils.formatTime(location.timestamp)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        location.eventType,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.map, color: Colors.blue, size: 16),
                        onPressed: () => _openGoogleMaps(
                            location.latitude, location.longitude),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Buka di Google Maps',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.devices, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Device: ${location.deviceId.isNotEmpty ? location.deviceId : 'Unknown'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.wifi, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'IP: ${location.ipAddress}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(ClientAddress address) {
    IconData icon;
    Color color;

    if (address.isHomeAddress) {
      icon = Icons.home;
      color = Colors.green;
    } else if (address.isOfficeAddress) {
      icon = Icons.business;
      color =
          Colors.indigo; // Changed from orange to indigo for better contrast
    } else {
      icon = Icons.location_on;
      color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: address.isDeliveryAddress
                          ? Colors.purple
                          : Colors.white,
                      width: address.isDeliveryAddress ? 3 : 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.addressTypeLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (address.isDeliveryAddress) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Delivery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (address.addressName.isNotEmpty)
                        Text(
                          address.addressName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showAddressDetails(address),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address.fullAddress,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.my_location,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${address.latitude.toStringAsFixed(6)}, Lng: ${address.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.map, color: Colors.blue, size: 16),
                        onPressed: () => _openGoogleMaps(
                            address.latitude, address.longitude),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Buka di Google Maps',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(ClientLocation location, int number) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: number == 1
                          ? Colors.green
                          : (number == _controller.locations.length
                              ? Colors.red
                              : Colors.blue),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          '${TimezoneUtils.formatIndonesianDate(location.timestamp)} ${TimezoneUtils.formatTime(location.timestamp)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Event Type', location.eventType),
              _buildDetailRow('Latitude', location.latitude.toStringAsFixed(6)),
              _buildDetailRow(
                  'Longitude', location.longitude.toStringAsFixed(6)),
              // Add Google Maps button
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Location:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'View on Maps',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.map,
                                color: Colors.blue, size: 20),
                            onPressed: () => _openGoogleMaps(
                                location.latitude, location.longitude),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Buka di Google Maps',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDetailRow('IP Address', location.ipAddress),
              _buildDetailRow('Device ID',
                  location.deviceId.isNotEmpty ? location.deviceId : 'Unknown'),
              _buildDetailRow('Skor User ID', location.skorUserId),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressDetails(ClientAddress address) {
    IconData icon;
    Color color;

    if (address.isHomeAddress) {
      icon = Icons.home;
      color = Colors.green;
    } else if (address.isOfficeAddress) {
      icon = Icons.business;
      color =
          Colors.indigo; // Changed from orange to indigo for better contrast
    } else {
      icon = Icons.location_on;
      color = Colors.grey;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: address.isDeliveryAddress
                            ? Colors.purple
                            : Colors.white,
                        width: address.isDeliveryAddress ? 3 : 2,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Address Details',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (address.isDeliveryAddress) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Delivery Address',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          address.addressTypeLabel,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Address Type', address.addressTypeLabel),
              if (address.addressName.isNotEmpty)
                _buildDetailRow('Address Name', address.addressName),
              _buildDetailRow('Address Line 1', address.addressLine1),
              if (address.addressLine2.isNotEmpty)
                _buildDetailRow('Address Line 2', address.addressLine2),
              if (address.addressLine3.isNotEmpty)
                _buildDetailRow('Address Line 3', address.addressLine3),
              _buildDetailRow('District', address.district),
              _buildDetailRow('City', address.city),
              _buildDetailRow('Province', address.province),
              _buildDetailRow('Postal Code', address.postalCode),
              _buildDetailRow('Latitude', address.latitude.toStringAsFixed(6)),
              _buildDetailRow(
                  'Longitude', address.longitude.toStringAsFixed(6)),
              // Add Google Maps button
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Location:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'View on Maps',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.map,
                                color: Colors.blue, size: 20),
                            onPressed: () => _openGoogleMaps(
                                address.latitude, address.longitude),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Buka di Google Maps',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildDetailRow('Is Delivery Address',
                  address.isDeliveryAddress ? 'Yes' : 'No'),
              _buildDetailRow('Skor User ID', address.skorUserId),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _openGoogleMaps(double latitude, double longitude) async {
    try {
      final url =
          Uri.parse('https://www.google.com/maps?q=$latitude,$longitude');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error membuka Google Maps'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
