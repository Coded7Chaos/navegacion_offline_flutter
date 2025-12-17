import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'presentation/main_screen.dart';
import 'repositories/data_repository.dart';
import 'blocs/user/user_bloc.dart';
import 'blocs/user/user_event.dart';
import 'blocs/map/map_bloc.dart';
import 'blocs/map/map_event.dart';
import 'blocs/home/home_bloc.dart';
import 'blocs/home/home_event.dart';
import 'blocs/alerts/alerts_bloc.dart';
import 'blocs/alerts/alerts_event.dart';
import 'blocs/navigation/navigation_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dataRepository = DataRepository();

  runApp(
    RepositoryProvider.value(
      value: dataRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UserBloc(prefs)..add(UserCheckRequested())),
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => MapBloc(repository: dataRepository)..add(MapStarted())),
          BlocProvider(create: (_) => HomeBloc(repository: dataRepository)..add(HomeStarted())),
          BlocProvider(create: (_) => AlertsBloc(repository: dataRepository)..add(AlertsStarted())),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navegación Offline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}
