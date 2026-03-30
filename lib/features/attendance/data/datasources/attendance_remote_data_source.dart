import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/error/failures.dart';

abstract class AttendanceRemoteDataSource {
  Future<void> submitDailyUpdate(String date, String token);
  Future<void> submitAttendance(String date, String token);
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final http.Client client;

  AttendanceRemoteDataSourceImpl({required this.client});

  @override
  Future<void> submitDailyUpdate(String date, String token) async {
    final response = await client.post(
      Uri.parse('https://api.placeholder.com/daily-update'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"date": date}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit daily update: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  @override
  Future<void> submitAttendance(String date, String token) async {
    final response = await client.post(
      Uri.parse('https://api.placeholder.com/attendance'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"date": date}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ServerException('Failed to submit attendance: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}
