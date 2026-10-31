
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/fastfit_motion.dart';
import '../../widgets/fastfit_brand.dart';
import 'smart_recommendation_screen.dart';
import 'nutrition_insights_screen.dart';
import 'meal_builder_screen.dart';
import 'fitness_hub_screen.dart';
import 'home_workouts_screen.dart';

import '../../services/food_service.dart';
import '../../services/customer_service.dart';
import 'food_details_screen.dart';

class UserDashboard extends StatefulWidget {
  final String name;
  const UserDashboard({super.key, required this.name});
  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int selectedPage = 0;
  static const titles = ['Discover', 'Favorites', 'Meal History', 'My Profile'];
  static const icons = [
    Icons.explore_outlined, Icons.favorite_border_rounded,
    Icons.history_rounded, Icons.person_outline_rounded,
  ];
  static const selectedIcons = [
    Icons.explore_rounded, Icons.favorite_rounded,
    Icons.history_rounded, Icons.person_rounded,
  ];

  Widget currentPage() => switch (selectedPage) {
    1 => const FavoritesPanel(),
    2 => const MealHistoryPanel(),
    3 => const ProfilePanel(),
    _ => HomePanel(name: widget.name),
  };

  Widget _sideItem(int index) {
    final active = selectedPage == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Material(color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => selectedPage = index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: .19) : Colors.transparent,
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(active ? selectedIcons[index] : icons[index],
                color: Colors.white,
                size: 21),
              const SizedBox(width: 13),
              Expanded(child: Text(titles[index],
                style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14))),
              if (active) const ContainerDot(),
            ]),
          ),
        ),
      ),
    );
  }

  Widget sidebar() => Container(
    width: 244,
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [FastFitStyle.red, FastFitStyle.deepRed])),
    child: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      const Padding(padding: EdgeInsets.fromLTRB(24, 28, 16, 18),
        child: FastFitLogo(onDark: true, size: 43)),
      const Padding(padding: EdgeInsets.fromLTRB(26, 24, 12, 12),
        child: Text('YOUR SPACE', style: TextStyle(
          color: Color(0xFFEED4D6), fontSize: 11,
          letterSpacing: 1.3, fontWeight: FontWeight.w800))),
      for (int i = 0; i < titles.length; i++) _sideItem(i),
      const Padding(padding: EdgeInsets.fromLTRB(26, 24, 12, 8),
        child: Text('STAY ACTIVE', style: TextStyle(
          color: Color(0xFFEED4D6), fontSize: 11,
          letterSpacing: 1.3, fontWeight: FontWeight.w800))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Material(color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const HomeWorkoutsScreen())),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(children: [
                Icon(Icons.fitness_center_rounded, size: 21, color: Colors.white),
                SizedBox(width: 13),
                Text('Workout categories', style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
              ]),
            ),
          ),
        ),
      ),
      const Spacer(),
      Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        )),
    ])),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 850;
      return Scaffold(
        backgroundColor: FastFitStyle.surface,
        appBar: desktop ? null : AppBar(
          title: const FastFitLogo(onDark: true, size: 34),
          backgroundColor: FastFitStyle.red,
          foregroundColor: Colors.white,
          actions: [
            IconButton(tooltip: 'Log out',
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout_outlined)),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(children: [
          if (desktop) sidebar(),
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(position: Tween<Offset>(
                begin: const Offset(.02, 0), end: Offset.zero)
                .animate(animation), child: child)),
            child: KeyedSubtree(key: ValueKey(selectedPage),
              child: currentPage()),
          )),
        ]),
        bottomNavigationBar: desktop ? null : NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.all(
              const IconThemeData(color: Colors.white)),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w700)),
          ),
          child: NavigationBar(
          height: 75,
          selectedIndex: selectedPage,
          onDestinationSelected: (i) => setState(() => selectedPage = i),
          backgroundColor: FastFitStyle.red,
          indicatorColor: const Color(0x44FFFFFF),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded), label: 'Discover'),
            NavigationDestination(icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
            NavigationDestination(icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded), label: 'History'),
            NavigationDestination(icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        )),
      );
    });
}

class ContainerDot extends StatelessWidget {
  const ContainerDot({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 7, width: 7,
    decoration: const BoxDecoration(
      color: Colors.white, shape: BoxShape.circle),
  );
}

// =====================================
// HOME: ACTIONABLE RESTAURANT CATALOG
// =====================================
class HomePanel extends StatefulWidget {
  final String name;
  const HomePanel({super.key, required this.name});
  @override
  State<HomePanel> createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> {
  String search = '';
  final FoodService service = FoodService();
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey restaurantAnchor = GlobalKey();

  @override
  void dispose() {
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void browseRestaurants() {
    final anchor = restaurantAnchor.currentContext;
    if (anchor != null) {
      Scrollable.ensureVisible(anchor,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: .06);
    }
  }

  void openScreen(Widget screen) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => screen));

  Widget _hero(bool compact) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(23),
      gradient: const LinearGradient(begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDC2F38), Color(0xFFAD1926)])),
    child: Stack(children: [
      Positioned(right: -60, top: -160,
        child: Container(width: 340, height: 340,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .085)))),
      Padding(padding: EdgeInsets.all(compact ? 22 : 31),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WELCOME TO YOUR ROUTINE',
                style: TextStyle(letterSpacing: 1.1,
                  color: Color(0xFFFFE4E5),
                  fontWeight: FontWeight.w800, fontSize: 10.5)),
              const SizedBox(height: 10),
              Text('Good food.\nBetter days.',
                style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w900, height: 1.12,
                  letterSpacing: -1, fontSize: compact ? 26 : 33)),
              const SizedBox(height: 10),
              const Text('Explore restaurant menus, compare nutrition, and build a routine that works for you.',
                style: TextStyle(color: Color(0xFFFFE7E8),
                  height: 1.5, fontSize: 13)),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: FastFitStyle.deepRed,
                  minimumSize: const Size(150, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11))),
                onPressed: browseRestaurants,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Explore menus',
                  style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          )),
        ]),
      ),
    ]),
  );

  Widget _toolLink(IconData icon, String title, String subtitle, Widget page,
    {required double width}) => SizedBox(
      width: width,
      child: Material(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => openScreen(page),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FastFitStyle.line)),
            child: Row(children: [
              Container(height: 44, width: 44,
                decoration: BoxDecoration(
                  color: FastFitStyle.softRed,
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: FastFitStyle.red, size: 23)),
              const SizedBox(width: 13),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FastFitStyle.ink,
                      fontWeight: FontWeight.w800, fontSize: 13.4)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: FastFitStyle.muted,
                      fontSize: 11.4, height: 1.4)),
                ])),
              const Icon(Icons.chevron_right_rounded,
                color: FastFitStyle.muted, size: 19),
            ]),
          ),
        ),
      ),
    );

  Widget _quickActions() => LayoutBuilder(builder: (context, c) {
    const gap = 12.0;
    final count = c.maxWidth < 680 ? 1 : 2;
    final width = (c.maxWidth - (count - 1) * gap) / count;
    return Wrap(spacing: gap, runSpacing: gap, children: [
      _toolLink(Icons.auto_awesome_outlined, 'Smart recommendations',
        'Food choices and activity suggestions',
        const SmartRecommendationScreen(), width: width),
      _toolLink(Icons.query_stats_rounded, 'Nutrition insights',
        'Explore the trends in your meal logs',
        const NutritionInsightsScreen(), width: width),
      _toolLink(Icons.lunch_dining_outlined, 'Build a meal',
        'Combine foods and log what you ate',
        const MealBuilderScreen(), width: width),
      _toolLink(Icons.fitness_center_outlined, 'Fitness hub',
        'Your workouts and activity history',
        const FitnessHubScreen(), width: width),
      _toolLink(Icons.fitness_center_rounded, 'Workout categories',
        'Explore full body, cardio, strength and mobility',
        const HomeWorkoutsScreen(), width: width),
    ]);
  });

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: scrollController,
    child: SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 23, 20, 110),
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hi, ${widget.name}!', maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: FastFitStyle.ink,
                  fontWeight: FontWeight.w900, letterSpacing: -.75,
                  fontSize: 27)),
              const SizedBox(height: 6),
              const Text('Make the next choice a good one.',
                style: TextStyle(color: FastFitStyle.muted, fontSize: 13)),
            ])),
            const SizedBox(width: 12),
            Container(height: 46, width: 46,
              decoration: BoxDecoration(color: FastFitStyle.softRed,
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.favorite_outline_rounded,
                color: FastFitStyle.red)),
          ]),
          const SizedBox(height: 25),
          LayoutBuilder(builder: (context, c) =>
            _hero(c.maxWidth < 600)),
          const SizedBox(height: 30),
          const Text('Your tools', style: TextStyle(
            color: FastFitStyle.ink,
            fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          const Text('Jump into the things you use most.',
            style: TextStyle(color: FastFitStyle.muted, fontSize: 13)),
          const SizedBox(height: 15),
          _quickActions(),
          const SizedBox(height: 35),
          Row(key: restaurantAnchor,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurants', style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w900,
                    color: FastFitStyle.ink)),
                  SizedBox(height: 5),
                  Text('Find meals from approved restaurants.',
                    style: TextStyle(fontSize: 12.5,
                      color: FastFitStyle.muted)),
                ])),
              const Icon(Icons.storefront_outlined, color: FastFitStyle.red),
            ]),
          const SizedBox(height: 17),
          TextField(
            controller: searchController,
            onChanged: (value) => setState(() =>
              search = value.trim().toLowerCase()),
            decoration: FastFitStyle.field('Search restaurants',
              Icons.search_rounded,
              hint: 'Search by restaurant name',
              suffix: search.isEmpty ? null : IconButton(
                tooltip: 'Clear search',
                onPressed: () { searchController.clear();
                  setState(() => search = ''); },
                icon: const Icon(Icons.close_rounded, size: 20))),
          ),
          const SizedBox(height: 17),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.approvedRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _HomeEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Restaurants are unavailable',
                  message: 'Please check your connection and try again.');
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(
                    color: FastFitStyle.red)));
              }
              final restaurants = snapshot.data!.docs.where((doc) {
                final name = doc.data()['name']?.toString().toLowerCase() ?? '';
                return name.contains(search);
              }).toList();
              if (restaurants.isEmpty) {
                return _HomeEmptyState(
                  icon: Icons.search_off_rounded,
                  title: search.isEmpty ? 'No restaurants yet' : 'No matches found',
                  message: search.isEmpty
                    ? 'Approved restaurants will appear here.'
                    : 'Try a different restaurant name.');
              }
              return LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 920 ? 3 : c.maxWidth >= 580 ? 2 : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: restaurants.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, crossAxisSpacing: 14,
                    mainAxisSpacing: 14, mainAxisExtent: 234),
                  itemBuilder: (context, index) {
                    final doc = restaurants[index];
                    final restaurant = doc.data();
                    final name = restaurant['name']?.toString() ?? 'Restaurant';
                    final logo = restaurant['logoUrl']?.toString() ?? '';
                    return FastFitHoverCard(
                      key: ValueKey(doc.id),
                      child: Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => openScreen(RestaurantMenuScreen(
                            restaurantId: doc.id, restaurantName: name)),
                          child: Column(children: [
                            Expanded(child: SizedBox(
                              width: double.infinity,
                              child: FoodPicture(imageUrl: logo,
                                fallbackIcon: Icons.storefront_outlined))),
                            Padding(padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Expanded(child: Text(name, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: FastFitStyle.ink, fontSize: 15.5,
                                    fontWeight: FontWeight.w800))),
                                Container(padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: FastFitStyle.softRed,
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.arrow_forward_rounded,
                                    color: FastFitStyle.red, size: 16)),
                              ])),
                          ]),
                        ),
                      ),
                    );
                  },
                );
              });
            },
          ),
        ]),
      )),
    ),
  );
}

class _HomeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _HomeEmptyState({required this.icon,
    required this.title, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: FastFitStyle.line)),
    child: Column(children: [
      Icon(icon, color: FastFitStyle.muted, size: 34),
      const SizedBox(height: 11),
      Text(title, style: const TextStyle(color: FastFitStyle.ink,
        fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center,
        style: const TextStyle(color: FastFitStyle.muted)),
    ]),
  );
}

// =====================================
// RESTAURANT MENU WITH SEARCH
// AND CATEGORY FILTERS
// =====================================

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState
    extends State<RestaurantMenuScreen> {
  String search = '';
  String selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.white,
        foregroundColor: FastFitStyle.ink,
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.restaurantName} Menu',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: FastFitStyle.ink,
              ),
            ),
            const SizedBox(height: 7),
            const Text('Explore the approved items on this menu.',
              style: TextStyle(color: FastFitStyle.muted, fontSize: 13)),
            const SizedBox(height: 18),

            TextField(
              decoration: FastFitStyle.field('Search food',
                Icons.search_rounded, hint: 'Find a menu item'),
              onChanged: (value) {
                setState(() {
                  search = value.toLowerCase().trim();
                });
              },
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FoodService().approvedFoods(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final allFoods = snapshot.data!.docs.where(
                    (doc) =>
                        doc.data()['restaurantId'] ==
                        widget.restaurantId,
                  ).toList();

                  final categories = <String>{'All'};

                  for (final doc in allFoods) {
                    final category =
                        doc.data()['category']?.toString() ?? '';

                    if (category.isNotEmpty) {
                      categories.add(category);
                    }
                  }

                  final foods = allFoods.where((doc) {
                    final food = doc.data();

                    final name =
                        food['name']?.toString().toLowerCase() ?? '';

                    final category =
                        food['category']?.toString() ?? '';

                    return name.contains(search) &&
                        (selectedCategory == 'All' ||
                            category == selectedCategory);
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((category) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(category),
                                selected:
                                    selectedCategory == category,
                                selectedColor: FastFitStyle.softRed,
                                onSelected: (_) {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      Expanded(
                        child: foods.isEmpty
                            ? const Center(
                                child: Text(
                                  'No approved food items found.',
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, size) {
                                  return FoodGrid(
                                    foods: foods,
                                    restaurantName:
                                        widget.restaurantName,
                                    columns: size.maxWidth >= 900
                                        ? 3
                                        : size.maxWidth >= 540
                                            ? 2
                                            : 1,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// SHARED FOOD CARDS
// =====================================

class FoodPicture extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;

  const FoodPicture({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = Icons.fastfood,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.red.shade50,
        child: Center(
          child: Icon(
            fallbackIcon,
            color: Colors.red,
            size: 55,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 330),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red.shade50,
          child: Center(
            child: Icon(
              fallbackIcon,
              color: Colors.red,
              size: 55,
            ),
          ),
        );
      },
    );
  }
}

class FoodGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> foods;
  final String restaurantName;
  final int columns;
  const FoodGrid({super.key, required this.foods,
    required this.restaurantName, required this.columns});

  String _measure(dynamic value) => value == null ? '—' : '$value';

  @override
  Widget build(BuildContext context) => GridView.builder(
    itemCount: foods.length,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      mainAxisExtent: 297,
    ),
    itemBuilder: (context, index) {
      final doc = foods[index];
      final food = doc.data();
      final imageUrl = food['imageUrl']?.toString() ?? '';
      final name = food['name']?.toString() ?? 'Food';
      return FastFitHoverCard(
        key: ValueKey(doc.id),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => FoodDetailsScreen(foodId: doc.id,
                food: food, restaurantName: restaurantName))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 151, width: double.infinity,
                  child: FoodPicture(imageUrl: imageUrl)),
                Expanded(child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FastFitStyle.ink,
                        fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const Spacer(),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: FastFitStyle.softRed),
                        child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                          const Icon(Icons.local_fire_department_outlined,
                            color: FastFitStyle.deepRed, size: 15),
                          const SizedBox(width: 4),
                          Text('${_measure(food['calories'])} kcal',
                            style: const TextStyle(
                              color: FastFitStyle.deepRed,
                              fontWeight: FontWeight.w800, fontSize: 12)),
                        ])),
                      const Spacer(),
                      const Icon(Icons.arrow_outward_rounded,
                        color: FastFitStyle.muted, size: 19),
                    ]),
                    const SizedBox(height: 8),
                    Text('Protein ${_measure(food['protein'])}g   '
                         'Carbs ${_measure(food['carbohydrates'])}g   '
                         'Fat ${_measure(food['fats'])}g',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: FastFitStyle.muted,
                        fontSize: 11)),
                  ]),
                )),
              ]),
          ),
        ),
      );
    },
  );
}

// =====================================
// FAVORITES
// =====================================

class FavoritesPanel extends StatelessWidget {
  const FavoritesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = CustomerService();
    final foodService = FoodService();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Favorite Foods',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: customer.favorites(),
              builder: (context, favoriteSnapshot) {
                if (favoriteSnapshot.hasError) {
                  return Text(
                    'Favorites error: ${favoriteSnapshot.error}',
                  );
                }

                if (!favoriteSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final favoriteIds = favoriteSnapshot.data!.docs
                    .map((doc) => doc.id)
                    .toSet();

                if (favoriteIds.isEmpty) {
                  return const Center(
                    child: Text('No favorite foods yet.'),
                  );
                }

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: foodService.approvedFoods(),
                  builder: (context, foodSnapshot) {
                    if (foodSnapshot.hasError) {
                      return Text(
                        'Food error: ${foodSnapshot.error}',
                      );
                    }

                    if (!foodSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final foods = foodSnapshot.data!.docs
                        .where(
                          (doc) => favoriteIds.contains(doc.id),
                        )
                        .toList();

                    if (foods.isEmpty) {
                      return const Center(
                        child: Text(
                          'Your saved foods are not currently '
                          'available on the approved menu.',
                        ),
                      );
                    }

                    return StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: foodService.approvedRestaurants(),
                      builder: (context, restaurantSnapshot) {
                        if (!restaurantSnapshot.hasData) {
                          if (restaurantSnapshot.hasError) {
                            return Text(
                              'Restaurant error: '
                              '${restaurantSnapshot.error}',
                            );
                          }

                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final names = <String, String>{};

                        for (final doc
                            in restaurantSnapshot.data!.docs) {
                          names[doc.id] =
                              doc.data()['name']?.toString() ??
                                  'Restaurant';
                        }

                        return LayoutBuilder(
                          builder: (context, size) {
                            return FoodGrid(
                              foods: foods,
                              restaurantName: '',
                              columns: size.maxWidth >= 900
                                  ? 3
                                  : size.maxWidth >= 540
                                      ? 2
                                      : 1,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// MEAL HISTORY
// =====================================

class MealHistoryPanel extends StatelessWidget {
  const MealHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CustomerService();

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Meal History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Meals you have chosen to record.',
          ),

          const SizedBox(height: 18),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: service.mealHistory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final logs = snapshot.data!.docs;

                if (logs.isEmpty) {
                  return const Center(
                    child: Text('No meals logged yet.'),
                  );
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final doc = logs[index];
                    final data = doc.data();

                    final calories =
                        (data['calories'] as num?)?.toDouble() ??
                            0;

                    final timestamp =
                        data['loggedAt'] as Timestamp?;

                    final date = timestamp?.toDate().toLocal();

                    final dateLabel = date == null
                        ? 'Just added'
                        : '${date.month}/${date.day}/${date.year}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['foodName']?.toString() ?? 'Meal',
                        ),
                        subtitle: Text(
                          '${data['restaurantName']}\n'
                          '$dateLabel • '
                          'Quantity: ${data['quantity']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete log',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) =>
                                      AlertDialog(
                                    title: const Text(
                                      'Delete Meal Log?',
                                    ),
                                    content: const Text(
                                      'Remove this meal '
                                      'from your history?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                          dialogContext,
                                          false,
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                          dialogContext,
                                          true,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await service.deleteMeal(doc.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// CUSTOMER FITNESS PROFILE
// =====================================

class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key});

  Future<void> editProfile(
    BuildContext context,
    Map<String, dynamic> profile,
  ) async {
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(
      text: profile['name']?.toString() ?? '',
    );

    final weight = TextEditingController(
      text: profile['weight']?.toString() ?? '',
    );

    final options = [
      'lose weight',
      'maintain weight',
      'gain weight',
    ];

    String goal = options.contains(profile['fitnessGoal'])
        ? profile['fitnessGoal']
        : 'maintain weight';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Fitness Profile'),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      TextFormField(
                        controller: weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          helperText: 'Used for exercise estimates',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) return null;

                          final number = double.tryParse(text);

                          if (number == null ||
                              !number.isFinite ||
                              number <= 0 ||
                              number > 500) {
                            return 'Enter a valid weight';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        initialValue: goal,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Goal',
                        ),
                        items: options.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => goal = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    try {
                      await CustomerService().saveProfile(
                        name: name.text,
                        fitnessGoal: goal,
                        weight: weight.text.trim().isEmpty
                            ? null
                            : double.parse(weight.text.trim()),
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext)
                            .showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    name.dispose();
    weight.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: CustomerService().profile(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final profile =
            snapshot.data!.data() ?? <String, dynamic>{};

        final name =
            profile['name']?.toString() ?? 'User';

        final email =
            profile['email']?.toString() ?? '';

        final goal =
            profile['fitnessGoal']?.toString() ?? 'Not set';

        final weight =
            profile['weight']?.toString() ?? 'Not set';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),
                  Text(email),

                  const SizedBox(height: 25),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.flag),
                          title: const Text('Fitness Goal'),
                          subtitle: Text(goal),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.monitor_weight,
                          ),
                          title: const Text('Current Weight'),
                          subtitle: Text(
                            weight == 'Not set'
                                ? weight
                                : '$weight kg',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: () {
                      editProfile(context, profile);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
