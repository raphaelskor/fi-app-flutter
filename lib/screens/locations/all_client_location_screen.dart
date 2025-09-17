import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/models/client.dart';
import '../../core/models/client_address.dart';
import '../../core/services/client_location_cache_service.dart';
import '../../core/services/client_id_mapping_service.dart';
import '../../core/services/location_service.dart';
import '../../core/controllers/client_controller.dart';
import '../../widgets/common_widgets.dart';
import '../clients/client_details_screen.dart';

class AllClientLocationScreen extends StatefulWidget {
  const AllClientLocationScreen({Key? key}) : super(key: key);

  @override
  State<AllClientLocationScreen> createState() =>
      _AllClientLocationScreenState();
}

class _AllClientLocationScreenState extends State<AllClientLocationScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _isCachingData = false; // New state for cache loading
  String? _errorMessage;
  Map<String, CachedLocationData> _allLocationData = {};
  List<_ClientLocationMarker> _allMarkers = [];
  bool _showHomeAddresses = true;
  bool _showOfficeAddresses = true;
  bool _showDeliveryAddresses = true;

  // User location
  Position? _userPosition;
  bool _isLoadingUserLocation = false;

  @override
  void initState() {
    super.initState();
    _loadAllLocationData();
    _getCurrentLocation();
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

      // Auto-focus to user location if data has already been loaded
      if (!_isLoading && _allLocationData.isNotEmpty) {
        _autoFocusToUserLocation();
      }
    } catch (e) {
      setState(() {
        _isLoadingUserLocation = false;
      });
      debugPrint('❌ Error getting user location: $e');
    }
  }

  Future<void> _loadAllLocationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cacheService = ClientLocationCacheService.instance;
      _allLocationData = await cacheService.getAllCachedLocationData();

      if (_allLocationData.isEmpty) {
        setState(() {
          _errorMessage =
              'No cached location data found. Visit individual client location screens first to cache their data.';
          _isLoading = false;
        });
        return;
      }

      _buildMarkers();

      setState(() {
        _isLoading = false;
      });

      // Auto-focus to user location when screen opens
      _autoFocusToUserLocation();

      debugPrint(
          '✅ Loaded location data for ${_allLocationData.length} clients');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading location data: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error loading all location data: $e');
    }
  }

  void _buildMarkers() {
    _allMarkers.clear();

    debugPrint('🔍 Building markers with filters:');
    debugPrint('   - Show Home Addresses: $_showHomeAddresses');
    debugPrint('   - Show Office Addresses: $_showOfficeAddresses');
    debugPrint('   - Show Delivery Addresses: $_showDeliveryAddresses');

    for (final entry in _allLocationData.entries) {
      final skorUserId = entry.key;
      final locationData = entry.value;

      // Debug log for each location data
      debugPrint('🔍 Building markers for skorUserId: $skorUserId');
      debugPrint('   └─ clientId: ${locationData.clientId}');
      debugPrint('   └─ clientName: ${locationData.clientName}');
      debugPrint('   └─ clientPhone: ${locationData.clientPhone}');
      debugPrint('   └─ addresses: ${locationData.addresses.length}');

      // Add address markers
      for (final address in locationData.addresses) {
        if (address.latitude == 0.0 || address.longitude == 0.0) continue;

        debugPrint('   🏠 Address: ${address.addressTypeLabel}');
        debugPrint('      - isHomeAddress: ${address.isHomeAddress}');
        debugPrint('      - isOfficeAddress: ${address.isOfficeAddress}');
        debugPrint('      - isDeliveryAddress: ${address.isDeliveryAddress}');

        // NEW LOGIC: Check each filter independently
        bool shouldShowAddress = false;

        // Show if it's a home address and home filter is enabled
        if (address.isHomeAddress && _showHomeAddresses) {
          shouldShowAddress = true;
          debugPrint('      ✅ Showing: Home address filter enabled');
        }

        // Show if it's an office address and office filter is enabled
        if (address.isOfficeAddress && _showOfficeAddresses) {
          shouldShowAddress = true;
          debugPrint('      ✅ Showing: Office address filter enabled');
        }

        // Show if it's a delivery address and delivery filter is enabled
        if (address.isDeliveryAddress && _showDeliveryAddresses) {
          shouldShowAddress = true;
          debugPrint('      ✅ Showing: Delivery address filter enabled');
        }

        // If none of the filters match, skip this address
        if (!shouldShowAddress) {
          debugPrint('      ❌ Skipping: No matching filters enabled');
          continue;
        }

        debugPrint('      ✅ Adding marker for this address');

        _allMarkers.add(_ClientLocationMarker(
          skorUserId: skorUserId,
          address: address,
          cacheTimestamp: locationData.timestamp,
          clientId: locationData.clientId,
          clientName: locationData.clientName,
          clientPhone: locationData.clientPhone,
        ));
      }
    }

    // Debug summary
    final markersWithClientId = _allMarkers
        .where((m) => m.clientId != null && m.clientId!.isNotEmpty)
        .length;
    final deliveryMarkers =
        _allMarkers.where((m) => m.address.isDeliveryAddress).length;
    debugPrint('📍 Built ${_allMarkers.length} markers');
    debugPrint('📍 Markers with Client ID: $markersWithClientId');
    debugPrint('📍 Delivery address markers: $deliveryMarkers');
    debugPrint(
        '📍 Markers without Client ID: ${_allMarkers.length - markersWithClientId}');
  }

  void _autoFocusToUserLocation() {
    if (_userPosition != null) {
      debugPrint(
          '🎯 Auto-focusing to user location: ${_userPosition!.latitude}, ${_userPosition!.longitude}');
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0, // Appropriate zoom level for user location
      );
    } else {
      debugPrint(
          '📍 User location not available for auto-focus, will focus when location is obtained');
    }
  }

  /// Trigger data caching by refreshing client data from ClientController
  Future<void> _triggerDataCaching() async {
    setState(() {
      _isCachingData = true;
    });

    try {
      debugPrint('🔄 Triggering client data refresh to create cache...');

      // Get ClientController from context and trigger refresh
      final clientController = context.read<ClientController>();
      await clientController.refresh();

      debugPrint('✅ Client data refresh completed');

      // Wait a bit for cache to be written
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to load location data again
      await _loadAllLocationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Client data loaded successfully! Location cache should be available now.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error triggering data caching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading client data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCachingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Client Locations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _allMarkers.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'Filter Addresses',
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Update Client IDs'),
                  onTap: _updateClientIds,
                ),
                PopupMenuItem(
                  child: const Text('Debug Mappings'),
                  onTap: _showMappingInfo,
                ),
                PopupMenuItem(
                  child: const Text('Clear Cache'),
                  onTap: _clearCache,
                ),
                PopupMenuItem(
                  child: const Text('Cache Info'),
                  onTap: _showCacheInfo,
                ),
              ],
            ),
          ],
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
            onPressed: _isLoadingUserLocation ? null : _getCurrentLocation,
            tooltip: 'Get My Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAllLocationData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading bar for cache operations
          if (_isCachingData)
            Container(
              height: 3,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
              ),
            ),

          // Main content
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading all client locations...');
    }

    if (_errorMessage != null) {
      return AppErrorWidget(
        message: _errorMessage!,
        onRetry: _loadAllLocationData,
      );
    }

    if (_allMarkers.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMap();
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
            'No Client Locations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Location data is not cached yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isCachingData ? null : _triggerDataCaching,
                icon: _isCachingData
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download),
                label: Text(_isCachingData
                    ? 'Loading Client Data...'
                    : 'Load Client Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will load client data and create location cache',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAllLocationData,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Calculate bounds to fit all markers
    if (_allMarkers.isEmpty) return _buildEmptyState();

    double minLat = _allMarkers
        .map((m) => m.address.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = _allMarkers
        .map((m) => m.address.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = _allMarkers
        .map((m) => m.address.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = _allMarkers
        .map((m) => m.address.longitude)
        .reduce((a, b) => a > b ? a : b);

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
                      '${_allLocationData.length} clients • ${_allMarkers.length} addresses',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 32),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (_userPosition != null)
                        _buildLegendItem(
                            Icons.person_pin, 'My Location', Colors.blue),
                      if (_showHomeAddresses)
                        _buildLegendItem(Icons.home, 'Home', Colors.green),
                      if (_showOfficeAddresses)
                        _buildLegendItem(
                            Icons.business, 'Office', Colors.indigo),
                      if (_showDeliveryAddresses)
                        _buildLegendItem(
                            Icons.local_shipping, 'Delivery', Colors.purple),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(centerLat, centerLng),
              initialZoom: 10.0,
              maxZoom: 18.0,
              minZoom: 3.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skorcard.field_investigator_app',
              ),
              MarkerLayer(
                markers: [
                  ..._buildMapMarkers(),
                  if (_userPosition != null) _buildUserLocationMarker(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  List<Marker> _buildMapMarkers() {
    return _allMarkers.map((markerData) {
      final address = markerData.address;
      IconData icon;
      Color color;

      if (address.isHomeAddress) {
        icon = Icons.home;
        color = Colors.green;
      } else if (address.isOfficeAddress) {
        icon = Icons.business;
        color = Colors.indigo;
      } else {
        icon = Icons.location_on;
        color = Colors.grey;
      }

      return Marker(
        point: LatLng(address.latitude, address.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showAddressDetails(markerData),
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

  Marker _buildUserLocationMarker() {
    return Marker(
      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _showUserLocationDetails(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_pin,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  void _showUserLocationDetails() {
    if (_userPosition == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Current Location',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Field Investigator Position',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
                'Latitude', _userPosition!.latitude.toStringAsFixed(6)),
            _buildDetailRow(
                'Longitude', _userPosition!.longitude.toStringAsFixed(6)),
            _buildDetailRow('Accuracy',
                '${_userPosition!.accuracy.toStringAsFixed(1)} meters'),
            _buildDetailRow('Timestamp', _userPosition!.timestamp.toString()),
            // Add Google Maps button
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Navigation:',
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
                              _userPosition!.latitude,
                              _userPosition!.longitude),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recalibrate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  void _showAddressDetails(_ClientLocationMarker markerData) async {
    final address = markerData.address;

    // Debug log for address details
    debugPrint('📋 Showing address details:');
    debugPrint('   └─ skorUserId: ${markerData.skorUserId}');
    debugPrint('   └─ clientId: ${markerData.clientId}');
    debugPrint('   └─ clientName: ${markerData.clientName}');
    debugPrint('   └─ clientPhone: ${markerData.clientPhone}');

    // Get Client ID from mapping service using Skor User ID
    String? clientId = markerData.clientId;
    String? clientName = markerData.clientName;
    String? clientPhone = markerData.clientPhone;

    // Always check mapping service for Client ID based on Skor User ID
    try {
      final mappingService = ClientIdMappingService.instance;
      final mappedClientId =
          await mappingService.getClientId(markerData.skorUserId);

      if (mappedClientId != null && mappedClientId.isNotEmpty) {
        clientId = mappedClientId;
        debugPrint('✅ Found Client ID from mapping: $clientId');
      } else {
        debugPrint(
            '❌ No Client ID mapping found for Skor User ID: ${markerData.skorUserId}');
      }
    } catch (e) {
      debugPrint('❌ Error checking mapping service: $e');
    }

    debugPrint('   └─ Final clientId: $clientId');
    debugPrint(
        '   └─ Will show button: ${clientId != null && clientId.isNotEmpty}');

    IconData icon;
    Color color;

    if (address.isHomeAddress) {
      icon = Icons.home;
      color = Colors.green;
    } else if (address.isOfficeAddress) {
      icon = Icons.business;
      color = Colors.indigo;
    } else {
      icon = Icons.location_on;
      color = Colors.grey;
    }

    if (!mounted) return;
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
                              'Client Address',
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
              _buildDetailRow('Skor User ID', markerData.skorUserId),
              // Show client information if available
              if (clientId != null) _buildDetailRow('Client ID', clientId),
              if (clientName != null)
                _buildDetailRow('Client Name', clientName),
              if (clientPhone != null) _buildDetailRow('Phone', clientPhone),
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
              _buildDetailRow('Cache Age',
                  '${markerData.cacheTimestamp.difference(DateTime.now()).abs().inHours}h ${markerData.cacheTimestamp.difference(DateTime.now()).abs().inMinutes % 60}m ago'),
              const SizedBox(height: 16),
              // Navigation button to client details (only if Client ID is available)
              if (clientId != null && clientId.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _navigateToClientDetails(_ClientLocationMarker(
                          skorUserId: markerData.skorUserId,
                          address: markerData.address,
                          cacheTimestamp: markerData.cacheTimestamp,
                          clientId: clientId,
                          clientName: clientName,
                          clientPhone: clientPhone,
                        )),
                        icon: const Icon(Icons.person),
                        label: const Text('View Client Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Client details not available. Visit "List Clients" tab first to load client data and create mappings.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Address Types'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Home Addresses'),
                subtitle: Text(
                    '${_allLocationData.values.expand((data) => data.addresses.where((a) => a.isHomeAddress)).length} addresses'),
                value: _showHomeAddresses,
                onChanged: (value) {
                  setDialogState(() {
                    _showHomeAddresses = value ?? true;
                  });
                },
                secondary: const Icon(Icons.home, color: Colors.green),
              ),
              CheckboxListTile(
                title: const Text('Office Addresses'),
                subtitle: Text(
                    '${_allLocationData.values.expand((data) => data.addresses.where((a) => a.isOfficeAddress)).length} addresses'),
                value: _showOfficeAddresses,
                onChanged: (value) {
                  setDialogState(() {
                    _showOfficeAddresses = value ?? true;
                  });
                },
                secondary: const Icon(Icons.business, color: Colors.indigo),
              ),
              CheckboxListTile(
                title: const Text('Delivery Addresses'),
                subtitle: Text(
                    '${_allLocationData.values.expand((data) => data.addresses.where((a) => a.isDeliveryAddress)).length} addresses'),
                value: _showDeliveryAddresses,
                onChanged: (value) {
                  setDialogState(() {
                    _showDeliveryAddresses = value ?? true;
                  });
                },
                secondary:
                    const Icon(Icons.local_shipping, color: Colors.purple),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _buildMarkers();
              });
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
            'Are you sure you want to clear all cached location data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final cacheService = ClientLocationCacheService.instance;
        await cacheService.clearAllCache();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );

          _loadAllLocationData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing cache: $e')),
          );
        }
      }
    }
  }

  void _updateClientIds() async {
    try {
      debugPrint('🔄 Updating Client IDs in location cache...');

      final cacheService = ClientLocationCacheService.instance;
      await cacheService.updateClientIdInCache();

      // Reload location data to reflect changes
      await _loadAllLocationData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client IDs updated successfully. Cache refreshed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating Client IDs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating Client IDs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMappingInfo() async {
    try {
      final mappingService = ClientIdMappingService.instance;
      final mappings = await mappingService.getClientIdMappings();

      debugPrint('🔍 Current Client ID mappings:');
      for (final entry in mappings.entries) {
        debugPrint(
            '   └─ Skor User ID: ${entry.key} → Client ID: ${entry.value}');
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Client ID Mappings'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total mappings: ${mappings.length}'),
                const SizedBox(height: 16),
                if (mappings.isEmpty)
                  const Text(
                      'No Client ID mappings found.\nVisit List Clients tab first to load client data and create mappings.')
                else
                  ...mappings.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Skor User ID: ${entry.key}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text('Client ID: ${entry.value}',
                                    style: const TextStyle(color: Colors.grey)),
                                const Divider(),
                              ],
                            ),
                          ))
                      .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing mapping info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mapping info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCacheInfo() async {
    final cacheService = ClientLocationCacheService.instance;
    final cacheInfo = await cacheService.getCacheInfo();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Clients: ${cacheInfo['totalClients']}'),
              Text('Location Keys: ${cacheInfo['locationKeys']}'),
              Text('Address Keys: ${cacheInfo['addressKeys']}'),
              Text('Cache Valid Duration: ${cacheInfo['cacheValidHours']}h'),
              const SizedBox(height: 16),
              Text('Currently Loaded: ${_allLocationData.length} clients'),
              Text('Total Markers: ${_allMarkers.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error membuka Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToClientDetails(_ClientLocationMarker markerData) async {
    debugPrint('🔍 Navigation attempt:');
    debugPrint('   - Skor User ID: ${markerData.skorUserId}');
    debugPrint('   - Client ID: ${markerData.clientId}');
    debugPrint('   - Client Name: ${markerData.clientName}');
    debugPrint('   - Client Phone: ${markerData.clientPhone}');

    // Check if we have Client ID, if not show error
    if (markerData.clientId == null || markerData.clientId!.isEmpty) {
      debugPrint('❌ Navigation failed: Client ID not available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Client ID not available. Visit the List Clients tab first to load client data and create mappings.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    debugPrint(
        '🔍 Looking for complete client data with Client ID: ${markerData.clientId}');

    // Try to get complete client data from ClientController
    Client? completeClient;
    try {
      // Try to access ClientController if available
      final clientController = context.read<ClientController>();
      final todaysClients = clientController.todaysClients;

      // Find the complete client data by Client ID
      completeClient = todaysClients.firstWhere(
        (client) => client.id == markerData.clientId,
        orElse: () => throw Exception('Client not found in today\'s clients'),
      );

      debugPrint('✅ Found complete client data from ClientController');
      debugPrint('   - Full Name: ${completeClient.name}');
      debugPrint('   - Phone: ${completeClient.phone}');
      debugPrint('   - Address: ${completeClient.address}');
      debugPrint('   - Status: ${completeClient.status}');
      debugPrint('   - Has rawApiData: ${completeClient.rawApiData != null}');
    } catch (e) {
      debugPrint('⚠️ Could not get complete client from ClientController: $e');
      debugPrint('🔄 Creating enhanced client object from available data...');

      // Fallback: Create enhanced client object with all available data
      try {
        // Get additional client info from mapping and cache
        final mappingService = ClientIdMappingService.instance;
        final allMappings = await mappingService.getClientIdMappings();

        // Find the reverse mapping to get more context
        String? skorUserIdFromMapping;
        for (final entry in allMappings.entries) {
          if (entry.value == markerData.clientId) {
            skorUserIdFromMapping = entry.key;
            break;
          }
        }

        debugPrint(
            '🔍 Found Skor User ID from mapping: $skorUserIdFromMapping');

        // Create a more complete Client object with all available location data
        completeClient = Client(
          id: markerData.clientId!, // Using the actual Client ID
          name: markerData.clientName ?? 'Unknown Client',
          address: _buildFullAddress(markerData.address),
          phone: markerData.clientPhone ?? '',
          email: null, // Will be populated from raw data if available
          latitude: markerData.address.latitude,
          longitude: markerData.address.longitude,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          notes: null,
          distance: null,
          rawApiData: {
            'id': markerData.clientId,
            'user_ID': skorUserIdFromMapping ?? markerData.skorUserId,
            'User_ID': skorUserIdFromMapping ?? markerData.skorUserId,
            'Name1': markerData.clientName,
            'Mobile': markerData.clientPhone,
            'CA_Line_1': markerData.address.addressLine1,
            'CA_Line_2': markerData.address.addressLine2,
            'CA_Line_3': markerData.address.addressLine3,
            'CA_City': markerData.address.city,
            'CA_Province': markerData.address.province,
            'CA_Postal_Code': markerData.address.postalCode,
            'CA_District': markerData.address.district,
            'Current_Status': 'active',
            'Address_Type': markerData.address.addressTypeLabel,
            'Is_Delivery_Address': markerData.address.isDeliveryAddress,
            'Address_Name': markerData.address.addressName,
            'Latitude': markerData.address.latitude,
            'Longitude': markerData.address.longitude,
            // Add cached timestamp for reference
            'Cache_Timestamp': markerData.cacheTimestamp.toIso8601String(),
          },
        );

        debugPrint('✅ Created enhanced client object with location data');
      } catch (e2) {
        debugPrint('❌ Error creating enhanced client data: $e2');
        // Final fallback to basic client object
        completeClient = Client(
          id: markerData.clientId!,
          name: markerData.clientName ?? 'Unknown Client',
          address: markerData.address.addressLine1,
          phone: markerData.clientPhone ?? '',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          rawApiData: {
            'user_ID': markerData.skorUserId,
            'id': markerData.clientId,
          },
        );
      }
    }

    debugPrint('🚀 Navigating to ClientDetailsScreen with complete data');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailsScreen(client: completeClient!),
      ),
    );
  }

  // Helper method to build full address string
  String _buildFullAddress(ClientAddress address) {
    final parts = <String>[];

    if (address.addressLine1.isNotEmpty) parts.add(address.addressLine1);
    if (address.addressLine2.isNotEmpty) parts.add(address.addressLine2);
    if (address.addressLine3.isNotEmpty) parts.add(address.addressLine3);
    if (address.district.isNotEmpty) parts.add(address.district);
    if (address.city.isNotEmpty) parts.add(address.city);
    if (address.province.isNotEmpty) parts.add(address.province);
    if (address.postalCode.isNotEmpty) parts.add(address.postalCode);

    return parts.join(', ');
  }
}

class _ClientLocationMarker {
  final String skorUserId;
  final ClientAddress address;
  final DateTime cacheTimestamp;
  final String? clientId;
  final String? clientName;
  final String? clientPhone;

  _ClientLocationMarker({
    required this.skorUserId,
    required this.address,
    required this.cacheTimestamp,
    this.clientId,
    this.clientName,
    this.clientPhone,
  });
}
