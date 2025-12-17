import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/navigation/navigation_cubit.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'registration_screen.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _screens = const [
    HomeScreen(),
    MapScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserInitial || state is UserLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is UserNeedsRegistration) {
          return const RegistrationScreen();
        }

        return BlocBuilder<NavigationCubit, int>(
          builder: (context, index) {
            return Scaffold(
              extendBody: true,
              body: IndexedStack(
                index: index,
                children: _screens,
              ),
              bottomNavigationBar: CustomBottomNavBar(
                currentIndex: index,
                onTap: context.read<NavigationCubit>().selectTab,
              ),
            );
          },
        );
      },
    );
  }
}
