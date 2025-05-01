part of 'water_level_bloc.dart';

@immutable
sealed class WaterLevelState {}

final class WaterLevelInitial extends WaterLevelState {}
class WaterLevelLoading extends WaterLevelState {}

class WaterLevelLoaded extends WaterLevelState {
  final WaterLevel? latestData;
  final List<WaterLevel> historyData;

  WaterLevelLoaded({required this.latestData, required this.historyData});
}


class WaterLevelError extends WaterLevelState {
  final String message;
  WaterLevelError({required this.message});
}
