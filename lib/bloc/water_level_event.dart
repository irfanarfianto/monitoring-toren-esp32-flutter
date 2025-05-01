part of 'water_level_bloc.dart';

@immutable
sealed class WaterLevelEvent {}


class StartWaterLevelStreamEvent extends WaterLevelEvent {}

class WaterLevelDataUpdatedEvent extends WaterLevelEvent {
  final List<Map<String, dynamic>> data;
  WaterLevelDataUpdatedEvent({required this.data});
}
