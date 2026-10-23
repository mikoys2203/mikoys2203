
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/food_service.dart';
import '../../services/customer_service.dart';
import 'food_details_screen.dart';

class UserDashboard extends StatefulWidget {
  final String name;

  const UserDashboard({
    super.key,
    required this.name,
  });

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int selectedPage = 0;

  final titles = [
    'Home',
    'Favorites',
    'Meal History',
    'My Profile',
  ];

  final icons = [
    Icons.home,
    Icons.favorite,
    Icons.history,
    Icons.person,
  ];

  Widget currentPage() {
    switch (selectedPage) {
      case 1:
        return const FavoritesPanel();
      case 2:
        return const MealHistoryPanel();
      case 3:
        return const ProfilePanel();
      default:
        return HomePanel(name: widget.name);
    }
  }

  Widget sidebar() {
    return Container(
      width: 215,
      color: Colors.red.shade700,
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            'FastFit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Eat smart. Stay active.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 35),

          for (int i = 0; i < titles.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: selectedPage == i
                    ? Colors.white24
                    : Colors.transparent,
                leading: Icon(
                  icons[i],
                  color: Colors.white,
                ),
                title: Text(
                  titles[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  setState(() => selectedPage = i);
                },
              ),
            ),

          const Spacer(),

          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 800;

        return Scaffold(
          appBar: AppBar(
            title: Text('FastFit - ${titles[selectedPage]}'),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            actions: [
              if (!desktop)
                IconButton(
                  tooltip: 'Log out',
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                ),
            ],
          ),

          body: Row(
            children: [
              if (desktop) sidebar(),

              Expanded(
                child: currentPage(),
              ),
            ],
          ),

          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: selectedPage,
                  onDestinationSelected: (index) {
                    setState(() => selectedPage = index);
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Favorites',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history),
                      label: 'History',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// =====================================
// HOME: RESTAURANT CATALOG
// =====================================

class HomePanel extends StatefulWidget {
  final String name;

  const HomePanel({
    super.key,
    required this.name,
  });

  @override
  State<HomePanel> createState() => _HomePanelState();
}

class _HomePanelState extends State<HomePanel> {
  String search = '';

  final FoodService service = FoodService();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.name}!',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore restaurants and check the nutrition '
            'of your favorite meals.',
          ),
          const SizedBox(height: 25),

          TextField(
            decoration: InputDecoration(
              hintText: 'Search restaurants...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                search = value.toLowerCase().trim();
              });
            },
          ),

          const SizedBox(height: 28),

          const Text(
            'Available Restaurants',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.approvedRestaurants(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Unable to load restaurants: ${snapshot.error}',
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final restaurants = snapshot.data!.docs.where((doc) {
                final name =
                    doc.data()['name']?.toString().toLowerCase() ?? '';
                return name.contains(search);
              }).toList();

              if (restaurants.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No restaurants found.'),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, size) {
                  final columns = size.maxWidth >= 900
                      ? 3
                      : size.maxWidth >= 550
                          ? 2
                          : 1;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: restaurants.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 235,
                    ),
                    itemBuilder: (context, index) {
                      final doc = restaurants[index];
                      final restaurant = doc.data();

                      final name =
                          restaurant['name']?.toString() ??
                              'Restaurant';

                      final logo =
                          restaurant['logoUrl']?.toString() ?? '';

                      return Card(
                        elevation: 1,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RestaurantMenuScreen(
                                  restaurantId: doc.id,
                                  restaurantName: name,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FoodPicture(
                                    imageUrl: logo,
                                    fallbackIcon: Icons.store,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(13),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.red,
                                      size: 17,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
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
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
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
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              decoration: const InputDecoration(
                hintText: 'Search food...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
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
                                selectedColor: Colors.red.shade100,
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

  const FoodGrid({
    super.key,
    required this.foods,
    required this.restaurantName,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: foods.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 275,
      ),
      itemBuilder: (context, index) {
        final doc = foods[index];
        final food = doc.data();

        final imageUrl =
            food['imageUrl']?.toString() ?? '';

        final name =
            food['name']?.toString() ?? 'Food';

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoodDetailsScreen(
                    foodId: doc.id,
                    food: food,
                    restaurantName: restaurantName,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 125,
                  child: FoodPicture(imageUrl: imageUrl),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),

                        Text(
                          '${food['calories']} kcal',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'P: ${food['protein']}g  '
                          'C: ${food['carbohydrates']}g  '
                          'F: ${food['fats']}g',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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
