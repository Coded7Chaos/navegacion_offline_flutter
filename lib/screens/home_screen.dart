import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map/map_bloc.dart';
import '../blocs/map/map_event.dart';
import '../blocs/navigation/navigation_cubit.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/home/home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Background color handled by theme
      body: SafeArea(
        bottom: false, // For floating nav bar
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          'Rutikal',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.primaryColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sistema Pumakatari - La Paz',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // ADS CAROUSEL
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (i) => setState(() {
                              _currentPage = i;
                            }),
                            itemCount: state.ads.length,
                            itemBuilder: (context, index) {
                              final ad = state.ads[index];
                              final isActive = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: EdgeInsets.only(
                                    right: 12,
                                    top: isActive ? 0 : 12,
                                    bottom: isActive ? 0 : 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        ad.imagen,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(color: Colors.grey[300]),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.6],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 20,
                                        right: 20,
                                        bottom: 20,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              ad.titulo,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              ad.descripcion,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            state.ads.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? theme.primaryColor
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // SECTION HEADER
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.directions_bus_rounded,
                                  color: theme.primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Rutas Disponibles',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ruta = state.rutas[index];
                        final color = _colorForIndex(index);
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                               BoxShadow(
                                 color: Colors.black.withOpacity(0.05),
                                 blurRadius: 10,
                                 offset: const Offset(0, 4),
                               ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                final routeId = ruta.idRutaPuma ?? index;
                                context
                                    .read<MapBloc>()
                                    .add(MapRouteSelected(routeId));
                                context
                                    .read<NavigationCubit>()
                                    .selectTab(1);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Image.asset(
                                            'assets/images/parada_bus.png',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Container(
                                           decoration: BoxDecoration(
                                             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                             color: color.withOpacity(0.85),
                                           ),
                                           child: Center(
                                             child: Icon(
                                               Icons.directions_bus_filled_rounded,
                                               color: Colors.white.withOpacity(0.9),
                                               size: 32,
                                             ),
                                           ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ruta.nombre,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: state.rutas.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100), // Space for floating nav bar
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _colorForIndex(int index) {
    const palette = [
      Color(0xFFE53E3E),
      Color(0xFF3182CE),
      Color(0xFF38A169),
      Color(0xFFD69E2E),
      Color(0xFFDD6B20),
      Color(0xFF805AD5),
    ];
    return palette[index % palette.length];
  }
}
