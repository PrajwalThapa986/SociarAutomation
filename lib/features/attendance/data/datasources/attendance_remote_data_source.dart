import 'package:http/http.dart' as http;
import '../../../../core/error/failures.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> submitAttendance(String date, String token);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final http.Client client;

  AttendanceRemoteDataSourceImpl({required this.client});

  @override
  Future<void> submitAttendance(String date, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://new-central-api.sociair.com/api/hris/attendance-request'),
    );

    // Add headers
    request.headers.addAll({
      'accept': 'application/json, text/plain, */*',
      'accept-encoding': 'gzip, deflate, br, zstd',
      'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'authorization': 'Bearer $token',
      'origin': 'https://ag.sociair.io',
      'referer': 'https://ag.sociair.io/',
      'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
      'x-requested-with': 'XMLHttpRequest',
    });

    // Derive fixed times based on the date being iterated
    // date format from UI: YYYY-MM-DD
    final requestDate = '${date}T18:15:00.000000Z';
    final checkIn = '${date}T03:15:00.000000Z';
    final checkOut = '${date}T12:15:00.000000Z';

    // Add form data
    request.fields['request_date'] = requestDate;
    request.fields['request_type'] = 'missing_punch_out';
    request.fields['hris_shift_type_id'] = '2';
    request.fields['remarks'] = 'work from DN';
    request.fields['check_in'] = checkIn;
    request.fields['check_out'] = checkOut;

    // Send the request via http.Client (we have to use client.send for multipart to allow mocking and DI benefits)
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit attendance: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}
