import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:water_level_arduino/bloc/water_level_bloc.dart';
import 'package:water_level_arduino/injection.dart';
import 'package:water_level_arduino/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jaewdybdjwobsyqxxkld.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphZXdkeWJkandvYnN5cXh4a2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYwMjcyMzMsImV4cCI6MjA2MTYwMzIzM30.moQIGJ9uxgPjEPVq529TNYLSeskKgyytB0C1gi_1POE',
  );

  await setupLocator();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WaterLevelBloc>()..add(StartWaterLevelStreamEvent()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter BLoC with Supabase',
        theme: ThemeData(primaryColor: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}
