
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/food_service.dart';
import '../../services/restaurant_media_service.dart';

class RestaurantMediaScreen extends StatefulWidget {
  const RestaurantMediaScreen({super.key});

  @override
  State<RestaurantMediaScreen> createState() =>
      _RestaurantMediaScreenState();
}

class _RestaurantMediaScreenState
    extends State<RestaurantMediaScreen> {
  final FoodService foodService = FoodService();
  final RestaurantMediaService mediaService =
      RestaurantMediaService();

  String imageType = 'logo';
  String? selectedFoodId;

  Uint8List? imageBytes;
  String imageName = '';
  String imageExtension = '';
  String imageContentType = '';

  bool uploading = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Detect supported image formats from the file bytes.
  String? detectExtension(Uint8List data) {
    if (data.length < 12) return null;

    // PNG
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'png';
    }

    // JPEG
    if (data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return 'jpg';
    }

    // WEBP
    if (data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return 'webp';
    }

    return null;
  }

  String contentTypeFor(String extension) {
    if (extension == 'png') return 'image/png';
    if (extension == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> selectImage() async {
    if (uploading) return;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file == null) return;

      final length = await file.length();

      if (length == null ||
          length <= 0 ||
          length > 4 * 1024 * 1024) {
        showMessage(
          'Please choose an image smaller than 4 MB.',
        );
        return;
      }

      final bytes = await file.readAsBytes();
      final extension = detectExtension(bytes);

      if (extension == null) {
        showMessage(
          'Only JPG, PNG, and WEBP images are supported.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        imageBytes = bytes;
        imageName = file.name;
        imageExtension = extension;
        imageContentType = contentTypeFor(extension);
      });
    } catch (e) {
      showMessage('Unable to select image: $e');
    }
  }

  Future<void> uploadImage() async {
    if (uploading || imageBytes == null) {
      showMessage('Please select an image first.');
      return;
    }

    if (imageType == 'food' && selectedFoodId == null) {
      showMessage('Select a food item first.');
      return;
    }

    setState(() => uploading = true);

    try {
      final restaurantRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(foodService.uid);

      // Restaurant profile must already exist.
      final restaurant = await restaurantRef.get();

      if (!restaurant.exists) {
        throw Exception(
          'Create your restaurant profile first.',
        );
      }

      DocumentReference<Map<String, dynamic>>? foodRef;
      Map<String, dynamic>? selectedFood;

      if (imageType == 'food') {
        foodRef = FirebaseFirestore.instance
            .collection('food_items')
            .doc(selectedFoodId);

        final foodDocument = await foodRef.get();

        if (!foodDocument.exists) {
          throw Exception('Food item was not found.');
        }

        selectedFood = foodDocument.data()!;

        if (selectedFood['restaurantId'] !=
            foodService.uid) {
          throw Exception('You do not own this food item.');
        }
      }

      final imageUrl = await mediaService.uploadImage(
        bytes: imageBytes!,
        contentType: imageContentType,
        extension: imageExtension,
      );

      if (imageType == 'logo') {
        await restaurantRef.update({
          'logoUrl': imageUrl,
        });
      } else {
        final food = selectedFood!;

        // Keep all original nutrition data.
        // Only the image changes.
        await foodService.saveFood(
          {
            'name': food['name'],
            'category': food['category'],
            'description': food['description'],
            'imageUrl': imageUrl,
            'servingSize': food['servingSize'],
            'calories': food['calories'],
            'protein': food['protein'],
            'carbohydrates': food['carbohydrates'],
            'fats': food['fats'],
          },
          foodId: selectedFoodId,
        );
      }

      if (!mounted) return;

      showMessage(
        imageType == 'logo'
            ? 'Restaurant logo updated!'
            : 'Food image submitted for admin approval!',
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Widget imagePreview() {
    if (imageBytes == null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 60,
              color: Colors.red,
            ),
            SizedBox(height: 10),
            Text('No image selected'),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget foodSelector() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: foodService.myFoods(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final foods = snapshot.data!.docs;

        if (foods.isEmpty) {
          return const Text(
            'No food items available. '
            'Please create a food item first.',
          );
        }

        final selectedExists = foods.any(
          (doc) => doc.id == selectedFoodId,
        );

        return DropdownButtonFormField<String>(
          key: ValueKey(
            selectedExists ? selectedFoodId : 'no-food',
          ),
          initialValue:
              selectedExists ? selectedFoodId : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Food Item',
            border: OutlineInputBorder(),
          ),
          items: foods.map((doc) {
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                doc.data()['name']?.toString() ?? 'Food',
              ),
            );
          }).toList(),
          onChanged: uploading
              ? null
              : (value) {
                  setState(() {
                    selectedFoodId = value;
                  });
                },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Restaurant Images'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 650,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FastFit Image Manager',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Upload your restaurant logo '
                  'or food product images.',
                ),

                const SizedBox(height: 25),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Restaurant Logo'),
                      selected: imageType == 'logo',
                      selectedColor: Colors.red.shade100,
                      onSelected: uploading
                          ? null
                          : (_) {
                              setState(() {
                                imageType = 'logo';
                              });
                            },
                    ),
                    ChoiceChip(
                      label: const Text('Food Image'),
                      selected: imageType == 'food',
                      selectedColor: Colors.red.shade100,
                      onSelected: uploading
                          ? null
                          : (_) {
                              setState(() {
                                imageType = 'food';
                              });
                            },
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                if (imageType == 'food') ...[
                  foodSelector(),
                  const SizedBox(height: 20),
                ],

                imagePreview(),

                const SizedBox(height: 15),

                if (imageName.isNotEmpty)
                  Text(
                    'Selected file: $imageName',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Choose Image'),
                    onPressed:
                        uploading ? null : selectImage,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      uploading
                          ? 'Uploading...'
                          : 'Upload to Firebase',
                    ),
                    onPressed:
                        uploading ? null : uploadImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                if (uploading) ...[
                  const SizedBox(height: 15),
                  const LinearProgressIndicator(),
                ],

                const SizedBox(height: 25),

                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(15),
                    child: Text(
                      'Accepted formats: JPG, PNG, WEBP.\n'
                      'Maximum file size: 4 MB.\n\n'
                      'Updating a food image submits '
                      'the food item for admin review again.\n\n'
                      'Firebase Storage requires an enabled '
                      'Storage bucket and appropriate permissions.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
