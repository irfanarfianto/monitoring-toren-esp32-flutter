import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:water_level_arduino/bloc/water_level_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Supabase harus sudah di-inisialisasi sebelum dipakai
  final supabase = Supabase.instance.client;

  getIt.registerSingleton<SupabaseClient>(supabase);

  // Register BLoC (bisa singleton atau factory)
  getIt.registerFactory<WaterLevelBloc>(
    () => WaterLevelBloc(supabaseClient: getIt<SupabaseClient>()),
  );
}
