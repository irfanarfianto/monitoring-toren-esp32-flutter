import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:water_level_arduino/models/water_level_model.dart';

part 'water_level_event.dart';
part 'water_level_state.dart';

class WaterLevelBloc extends Bloc<WaterLevelEvent, WaterLevelState> {
  final SupabaseClient supabaseClient;
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  WaterLevelBloc({required this.supabaseClient}) : super(WaterLevelInitial()) {
    on<StartWaterLevelStreamEvent>(_onStartStream);
    on<WaterLevelDataUpdatedEvent>(_onDataUpdated);
  }

  void _onStartStream(
    StartWaterLevelStreamEvent event,
    Emitter<WaterLevelState> emit,
  ) {
    emit(WaterLevelLoading());

    _subscription?.cancel();

    _subscription = supabaseClient
        .from('water_levels')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(10)
        .listen((data) {
          add(WaterLevelDataUpdatedEvent(data: data));
        });
  }

  void _onDataUpdated(
    WaterLevelDataUpdatedEvent event,
    Emitter<WaterLevelState> emit,
  ) {
    if (event.data.isEmpty) {
      emit(WaterLevelLoaded(latestData: null, historyData: []));
    } else {
      final latest = WaterLevel.fromJson(event.data.first);
      final history =
          event.data.skip(1).map((e) => WaterLevel.fromJson(e)).toList();
      emit(WaterLevelLoaded(latestData: latest, historyData: history));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
