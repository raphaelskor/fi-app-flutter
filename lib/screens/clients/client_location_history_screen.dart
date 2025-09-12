import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/client_location_controller.dart';
import '../../core/models/client.dart';
import '../../core/models/client_location.dart';
import '../../core/utils/timezone_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = ClientLocationController();

    // Initialize with skorUserId from client
    final skorUserId = widget.client.skorUserId;
    if (skorUserId != null && skorUserId.isNotEmpty) {
      _controller.initialize(skorUserId);
    } else {
      // Set error using the controller's public method
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.clearError();
        // We'll handle this in the UI by showing appropriate message
      });
    }
  }

  @override
  void dispose() {
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
                  return IconButton(
                    icon: Icon(_showLocationList ? Icons.map : Icons.list),
                    tooltip: _showLocationList ? 'Show Map' : 'Show List',
                    onPressed: () {
                      setState(() {
                        _showLocationList = !_showLocationList;
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
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
        if (controller.locations.isEmpty) {
          return _buildEmptyState();
        }
        return _showLocationList
            ? _buildLocationList(controller.locations)
            : _buildMap(controller.locations);
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
            'No Location History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No location data found for this client',
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

  Widget _buildMap(List<ClientLocation> locations) {
    // Calculate bounds to fit all markers
    double minLat =
        locations.map((l) => l.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        locations.map((l) => l.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        locations.map((l) => l.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        locations.map((l) => l.longitude).reduce((a, b) => a > b ? a : b);

    // Center of all locations
    double centerLat = (minLat + maxLat) / 2;
    double centerLng = (minLng + maxLng) / 2;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${locations.length} location records found',
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
              MarkerLayer(
                markers: _buildMarkers(locations),
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: locations
                        .map((l) => LatLng(l.latitude, l.longitude))
                        .toList(),
                    strokeWidth: 2.0,
                    color: Colors.blue.withOpacity(0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<ClientLocation> locations) {
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

  Widget _buildLocationList(List<ClientLocation> locations) {
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
                  '${locations.length} location records',
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
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return _buildLocationCard(location, index + 1);
            },
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
}
