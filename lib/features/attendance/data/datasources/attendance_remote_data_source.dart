import 'package:http/http.dart' as http;

import 'package:injectable/injectable.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> submitAttendance(String date, String token);
  Future<void> submitWorklog(String date, String token, String logContent);
}

@LazySingleton(as: AttendanceRemoteDataSource)
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
    final checkIn = '09:00';
    final checkOut = '18:00';

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

  @override
  Future<void> submitWorklog(String date, String token, String logContent) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://new-central-api.sociair.com/api/hris/worklog'),
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

    final htmlLog = "<p>$logContent</p>";

    // Date
    request.fields['date'] = date;
    
    // Entry 0 (Morning)
    request.fields['entries[0][start_time]'] = '09:00';
    request.fields['entries[0][end_time]'] = '13:00';
    request.fields['entries[0][mst_project_id]'] = '41';
    request.fields['entries[0][mst_kpi_id]'] = '';
    request.fields['entries[0][activity_type]'] = '';
    request.fields['entries[0][mst_dynamic_form_id]'] = '';
    request.fields['entries[0][description]'] = htmlLog;
    request.fields['entries[0][dynamicForm]'] = '585';

    // Entry 1 (Afternoon)
    request.fields['entries[1][id]'] = DateTime.now().millisecondsSinceEpoch.toString();
    request.fields['entries[1][activity_type]'] = '';
    request.fields['entries[1][mst_dynamic_form_id]'] = '';
    request.fields['entries[1][mst_project_id]'] = '41';
    request.fields['entries[1][mst_kpi_id]'] = '';
    request.fields['entries[1][start_time]'] = '14:00';
    request.fields['entries[1][end_time]'] = '18:00';
    request.fields['entries[1][description]'] = htmlLog;
    request.fields['entries[1][dynamicForm]'] = '424';

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit worklog: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}
