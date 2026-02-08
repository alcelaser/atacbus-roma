import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';

class GtfsRealtimeApi {
  final http.Client _client;

  GtfsRealtimeApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Uint8List> fetchTripUpdates() async {
    return _fetchFeed(ApiConstants.gtfsRtTripUpdatesUrl);
  }

  Future<Uint8List> fetchVehiclePositions() async {
    return _fetchFeed(ApiConstants.gtfsRtVehiclePositionsUrl);
  }

  Future<Uint8List> fetchServiceAlerts() async {
    return _fetchFeed(ApiConstants.gtfsRtServiceAlertsUrl);
  }

  Future<Uint8List> _fetchFeed(String url) async {
    try {
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw ServerException(
          'Failed to fetch RT feed: $url',
          statusCode: response.statusCode,
        );
      }
      return response.bodyBytes;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Network error fetching RT feed: $e');
    }
  }
}
