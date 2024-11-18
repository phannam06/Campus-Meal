import 'dart:io';
import 'package:campus_catalogue/constants/colors.dart';
import 'package:campus_catalogue/constants/typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CategoryCard extends StatelessWidget {
  final String category;
  final Function(String) shiftCard;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.category,
    required this.shiftCard,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: AppColors.backgroundOrange),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category),
            GestureDetector(
              child: Icon(isSelected ? Icons.remove : Icons.add),
              onTap: () {
                shiftCard(category);
              },
            )
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class ItemEditor extends StatefulWidget {
  Map<String, dynamic> item;
  Function(Map<String, dynamic>) deleteItem;

  ItemEditor({
    super.key,
    required this.item,
    required this.deleteItem,
  });

  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  XFile? sampleImage;
  bool showName = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize default fields if not present
    widget.item.putIfAbsent('name', () => '');
    widget.item.putIfAbsent('description', () => '');
    widget.item.putIfAbsent('price', () => 0.0);
    widget.item.putIfAbsent('vegetarian', () => false);
    widget.item.putIfAbsent('category', () => <String>[]);
    widget.item.putIfAbsent('unselected_categories', () => <String>[]);
  }

  void shiftCard(String category) {
    if (widget.item['category'].contains(category)) {
      widget.item['category'].remove(category);
      widget.item['unselected_categories'].add(category);
    } else {
      widget.item['category'].add(category);
      widget.item['unselected_categories'].remove(category);
    }
    setState(() {});
  }

  Future<String> uploadImageToFirebase(File imageFile) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = storage.ref().child(fileName);

    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;

    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> getImage() async {
    try {
      var image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        XFile selectedImage = image;
        String downloadUrl =
            await uploadImageToFirebase(File(selectedImage.path));
        widget.item["img"] = downloadUrl;
        setState(() {
          sampleImage = selectedImage;
        });
        print("Image uploaded! URL: $downloadUrl");
      }
    } catch (e) {
      print("Lỗi khi tải ảnh lên: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải ảnh lên: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.signIn,
      child: ExpansionTile(
        onExpansionChanged: (value) {
          setState(() {
            showName = !value;
          });
        },
        initiallyExpanded: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedBackgroundColor: AppColors.signIn,
        iconColor: Colors.black,
        textColor: Colors.black,
        title: showName
            ? Text(
                widget.item['name'].isEmpty ? "New Item" : widget.item['name'],
                style:
                    AppTypography.textMd.copyWith(fontWeight: FontWeight.w600),
              )
            : const Text(''),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        expandedAlignment: Alignment.topLeft,
        children: [
          const Align(
            alignment: Alignment.topLeft,
            child: Text('Item Name'),
          ),
          const SizedBox(height: 5),
          TextFormField(
            onChanged: (name) {
              setState(() {
                widget.item['name'] = name;
              });
            },
            initialValue: widget.item['name'],
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.topLeft,
            child: Text('Price'),
          ),
          const SizedBox(height: 5),
          TextFormField(
            onChanged: (price) {
              setState(() {
                widget.item['price'] = double.tryParse(price) ?? 0.0;
              });
            },
            initialValue: widget.item['price'] == 0.0
                ? ''
                : widget.item['price'].toString(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            ],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                checkColor: AppColors.backgroundOrange,
                activeColor: AppColors.backgroundYellow,
                value: widget.item['vegetarian'],
                onChanged: (bool? val) {
                  setState(() {
                    widget.item['vegetarian'] = val ?? false;
                  });
                },
              ),
              const Text('Vegetarian'),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.topLeft,
            child: Text('Description'),
          ),
          const SizedBox(height: 5),
          TextFormField(
            onChanged: (description) {
              setState(() {
                widget.item['description'] = description;
              });
            },
            initialValue: widget.item['description'],
            maxLines: 2,
            decoration: const InputDecoration(
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.topLeft,
            child: Text('Image'),
          ),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: getImage,
            child: sampleImage == null &&
                    (widget.item['img'] == null || widget.item['img'].isEmpty)
                ? Center(
                    child: Container(
                      height: 150,
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.backgroundOrange, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.backgroundOrange,
                      ),
                    ),
                  )
                : Center(
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 100,
                        width: 150,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.backgroundOrange, width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.item['img'] != ''
                              ? Image.network(
                                  widget.item['img'],
                                  fit: BoxFit.cover,
                                )
                              : (sampleImage != null
                                  ? Image.file(
                                      File(sampleImage!.path),
                                      fit: BoxFit.cover,
                                    )
                                  : Container()),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          const Text('Relevant Tags'),
          const SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Wrap(
              children: widget.item['category'].map<Widget>((category) {
                return CategoryCard(
                  category: category,
                  shiftCard: shiftCard,
                  isSelected: true,
                );
              }).toList(),
            ),
          ),
          Wrap(
            children:
                widget.item['unselected_categories'].map<Widget>((category) {
              return CategoryCard(
                category: category,
                shiftCard: shiftCard,
                isSelected: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () {
                widget.deleteItem(widget.item);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class EditMenu extends StatefulWidget {
  final List<dynamic> menu;

  const EditMenu({super.key, required this.menu});

  @override
  State<EditMenu> createState() => _EditMenuState();
}

class _EditMenuState extends State<EditMenu> {
  List<String> allCategories = [];
  int itemCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    try {
      var snapshot = await db.collection('categories').get();
      setState(() {
        allCategories = snapshot.docs.map((doc) => doc.id).toList();
        // Update unselected_categories for existing items
        for (var item in widget.menu) {
          if (!item.containsKey('unselected_categories') ||
              item['unselected_categories'] == null) {
            item['unselected_categories'] = List<String>.from(allCategories);
          }
        }
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi khi lấy categories: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi lấy categories: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void deleteItem(Map<String, dynamic> item) {
    setState(() {
      widget.menu.remove(item);
    });
  }

  void addItem() {
    setState(() {
      widget.menu.add({
        'name': '',
        'price': 0.0,
        'vegetarian': false,
        'description': '',
        'category': <String>[],
        'img': '',
        'unselected_categories': List<String>.from(allCategories),
        'key': ++itemCount,
      });
    });
  }

  void doneEditing() {
    // Remove temporary fields if any
    for (var item in widget.menu) {
      item.remove('unselected_categories');
      // Remove 'id' if it exists, based on your original code
      item.remove('id');
      // You can add more cleanup here if necessary
      print(item);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundYellow,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Add Food Items',
              style: AppTypography.textMd.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 30),
            widget.menu.isEmpty
                ? SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        "Empty Menu",
                        style: AppTypography.textMd,
                      ),
                    ),
                  )
                : Column(
                    children: widget.menu.map((item) {
                      if (!item.containsKey('key')) {
                        item['key'] = ++itemCount;
                      }
                      return ItemEditor(
                        key: ValueKey(item['key']),
                        item: item,
                        deleteItem: deleteItem,
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: addItem,
                  child: Text(
                    '+Add Item',
                    style: AppTypography.textMd
                        .copyWith(color: AppColors.backgroundOrange),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: doneEditing,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundOrange,
                minimumSize: const Size(221, 40),
              ),
              child: const Text("Done"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

void edit_menu({required List menu, required BuildContext context}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditMenu(menu: menu),
    ),
  );
}
