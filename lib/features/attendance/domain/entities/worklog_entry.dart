import 'package:equatable/equatable.dart';

class WorklogEntry extends Equatable {
  final String startTime;
  final String endTime;
  final String description;

  const WorklogEntry({
    required this.startTime,
    required this.endTime,
    required this.description,
  });

  @override
  List<Object> get props => [startTime, endTime, description];
}
