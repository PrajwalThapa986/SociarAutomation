import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import '../../domain/entities/worklog_entry.dart';
import '../../../../core/error/exceptions.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> submitAttendance(String date, String token);
  Future<void> submitWorklog(String date, String token, List<WorklogEntry> entries);
  Future<List<int>> fetchPendingRequestIds(String token);
  Future<void> approveAttendanceRequest(int id, String token);
}

@LazySingleton(as: AttendanceRemoteDataSource)
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final http.Client client;

  AttendanceRemoteDataSourceImpl({required this.client});

  Map<String, String> _buildHeaders(String token) => {
    'accept': 'application/json, text/plain, */*',
    'accept-encoding': 'gzip, deflate, br, zstd',
    'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
    'authorization': 'Bearer $token',
    'origin': 'https://ag.sociair.io',
    'referer': 'https://ag.sociair.io/',
    'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36',
    'x-requested-with': 'XMLHttpRequest',
  };

  @override
  Future<void> submitAttendance(String date, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://new-central-api.sociair.com/api/hris/attendance-request'),
    );

    request.headers.addAll(_buildHeaders(token));

    // Derive fixed times
    final requestDate = '${date}T18:15:00.000000Z';
    const checkIn = '09:00';
    const checkOut = '18:00';

    // Add form data
    request.fields['request_date'] = requestDate;
    request.fields['request_type'] = 'missing_punch_out';
    request.fields['hris_shift_type_id'] = '2';
    request.fields['remarks'] = 'work from DN';
    request.fields['check_in'] = checkIn;
    request.fields['check_out'] = checkOut;

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit attendance: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }

  @override
  Future<void> submitWorklog(String date, String token, List<WorklogEntry> entries) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://new-central-api.sociair.com/api/hris/worklog'),
    );

    request.headers.addAll(_buildHeaders(token));

    // Date
    request.fields['date'] = date;
    
    for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final prefix = 'entries[$i]';
        
        request.fields['$prefix[start_time]'] = entry.startTime;
        request.fields['$prefix[end_time]'] = entry.endTime;
        request.fields['$prefix[description]'] = "<p>${entry.description}</p>";
        request.fields['$prefix[mst_project_id]'] = '41';
        request.fields['$prefix[mst_kpi_id]'] = '';
        request.fields['$prefix[activity_type]'] = '';
        request.fields['$prefix[mst_dynamic_form_id]'] = '';
        
        // Dynamic Form Mapping
        request.fields['$prefix[dynamicForm]'] = i == 0 ? '585' : '424';
        
        if (i > 0) {
            request.fields['$prefix[id]'] = (DateTime.now().millisecondsSinceEpoch + i).toString();
        }
    }

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit worklog: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }

  @override
  Future<List<int>> fetchPendingRequestIds(String token) async {
    final List<int> pendingIds = [];
    int currentPage = 1;
    int lastPage = 1;

    do {
      final uri = Uri.parse(
        'https://new-central-api.sociair.com/api/hris/subordinate/attendance-request',
      ).replace(queryParameters: {
        'page': currentPage.toString(),
        'rowsPerPage': '25',
        'query': '',
        'filters': '{}',
        'descending': 'true',
        'sortBy': 'id',
        'view': 'table',
      });

      final response = await client.get(uri, headers: _buildHeaders(token));

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch attendance requests: ${response.statusCode} ${response.reasonPhrase}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>;
      final meta = json['meta'] as Map<String, dynamic>;

      lastPage = meta['last_page'] as int;

      for (final item in data) {
        if ((item['status'] as int) == 0) {
          pendingIds.add(item['id'] as int);
        }
      }

      currentPage++;
    } while (currentPage <= lastPage);

    return pendingIds;
  }

  @override
  Future<void> approveAttendanceRequest(int id, String token) async {
    final uri = Uri.parse(
      'https://new-central-api.sociair.com/api/hris/attendance-request/$id/set-status',
    );

    final headers = {
      ..._buildHeaders(token),
      'content-type': 'application/json',
    };

    final response = await client.post(
      uri,
      headers: headers,
      body: jsonEncode({'status': 'APPROVED', 'remarks': '', 'rejection_reason': null}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to approve request #$id: ${response.statusCode} ${response.reasonPhrase}\n${response.body}');
    }
  }
}

