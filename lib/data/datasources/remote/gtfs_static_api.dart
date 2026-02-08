import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/error/exceptions.dart';

class GtfsStaticApi {
  final http.Client _client;

  GtfsStaticApi({http.Client? client}) : _client = client ?? http.Client();

  Future<http.StreamedResponse> downloadGtfsZip() async {
    final request = http.Request('GET', Uri.parse(ApiConstants.gtfsStaticUrl));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw ServerException(
        'Failed to download GTFS ZIP',
        statusCode: response.statusCode,
      );
    }
    return response;
  }
}
