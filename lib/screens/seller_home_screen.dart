import 'package:campus_catalogue/add_item.dart';
import 'package:campus_catalogue/constants/colors.dart';
import 'package:campus_catalogue/constants/typography.dart';
import 'package:campus_catalogue/models/order_model.dart';
import 'package:campus_catalogue/models/shopModel.dart';
import 'package:campus_catalogue/screens/login.dart';
import 'package:campus_catalogue/screens/add_menu.dart';
import 'package:campus_catalogue/screens/Scanner/qr_code_scanner.dart';
import 'package:campus_catalogue/screens/Scanner/scanner.dart';
import 'package:campus_catalogue/screens/sele_buyer.dart';
import 'package:campus_catalogue/screens/update_menu.dart';
import 'package:campus_catalogue/screens/userType_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_catalogue/services/database_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderWrapper extends StatelessWidget {
  final List<dynamic> orders;
  const OrderWrapper({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Column(
            children: [
              OrderTile(
                buyerName: order["buyer_name"],
                buyerPhone: order["buyer_phone"],
                status: order["status"],
                totalAmount: order["total_amount"],
                txnId: order["txnId"],
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ShopModel shop;
  const HomePage({super.key, required this.shop});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List card = [];
  bool isLoading = true;
  String errorMessage = '';
  num totalIncome = 0;
  List menu = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
    initializeMenu();
  }

  Future<void> fetchOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shop_name', isEqualTo: widget.shop.shopName)
          .get();

      setState(() {
        card = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;

          totalIncome += (data['price'] ?? 0);
          return [
            data['buyer_name'] ?? 'Unknown',
            data['order_name'] ?? 'Unknown',
            data['price'] ?? 0,
            data['date'] ?? 'Unknown',
            data['img'] ?? 'Unknown', // Đảm bảo 'img' tồn tại trong Firestore
          ];
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orders: $e';
        isLoading = false;
      });
      print('Error fetching orders: $e');
    }
  }

  // List<Map<String, dynamic>> menu = [];
  // void initializeMenu() {
  //   setState(() {
  //     menu = List<Map<String, dynamic>>.from(widget.shop.menu.map((item) => {
  //           "name": item["name"],
  //           "price": item["price"],
  //           "vegetarian": item["vegetarian"],
  //           "description": item["description"],
  //           "category": item["category"],
  //           "img": item['img']
  //         }));
  //     isLoading = false;
  //   });
  // }
  void initializeMenu() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Truy vấn Firestore dựa trên shop_id
      QuerySnapshot shopSnapshot = await FirebaseFirestore.instance
          .collection('shop')
          .where('shop_id', isEqualTo: widget.shop.shopID)
          .get();

      if (shopSnapshot.docs.isNotEmpty) {
        // Lấy document đầu tiên (giả sử mỗi shop_id là duy nhất)
        DocumentSnapshot shopDoc = shopSnapshot.docs.first;
        Map<String, dynamic> shopData = shopDoc.data() as Map<String, dynamic>;

        List<dynamic> firestoreMenu = shopData['menu'] ?? [];

        setState(() {
          menu = List<Map<String, dynamic>>.from(firestoreMenu.map((item) => {
                "name": item["name"],
                "price": item["price"],
                "vegetarian": item["vegetarian"],
                "description": item["description"],
                "category": item["category"],
                "img": item['img']
              }));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Trường hợp không tìm thấy shop
        print("Shop không tồn tại");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Xử lý lỗi truy xuất Firestore
      print("Lỗi khi truy xuất menu từ Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundYellow,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.backgroundOrange,
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const UserType())),
        ),
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            setState(() {
              initializeMenu();
            });
          },
          child: SingleChildScrollView(
            child: Text(
              "Explore IITG",
              style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          child: Column(
            // Thêm Column để chứa các widget
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIncomeCard(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store,
                    size: 24,
                    color: AppColors.backgroundOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Shop Management",
                    style: AppTypography.textMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildUpdateMenuButton(context),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.menu,
                    size: 24,
                    color: AppColors.backgroundOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Menu",
                    style: AppTypography.textMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              for (var item in menu)
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(
                          width: 2.3,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Đưa lên trên
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 10, bottom: 5),
                                  child: Text(
                                    "Name: ${item['name']}",
                                    style: AppTypography.textMd.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.backgroundOrange,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(
                                    "Price: Rs. ${item['price']}",
                                    style: AppTypography.textMd.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Description: ${item['description']}",
                                          style: AppTypography.textSm.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: AppColors.backgroundOrange
                                      .withOpacity(0.5),
                                  thickness: 1.5,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                item['img'],
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/iconshop.jpg',
                                    fit: BoxFit.fill,
                                    width: double.infinity,
                                    height: double.infinity,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.backgroundYellow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 3, color: AppColors.backgroundOrange),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total Income",
                style: AppTypography.textMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Rs. ${totalIncome.toString()}",
                style: AppTypography.textMd.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.backgroundOrange,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "UPI ID",
                style: AppTypography.textMd.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.shop.upiId,
                style: AppTypography.textMd.copyWith(
                  fontSize: 14,
                  color: AppColors.backgroundOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateMenuButton(BuildContext context) {
    final List<String> items = ["Update Menu", "Add Menu"];

    return Center(
      child: SizedBox(
        height: 100, // Đảm bảo chiều cao cho ListView
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                if (index == 0) {
                  // Điều hướng đến trang chỉnh sửa menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            UpdateMenuItemPage(shop: widget.shop, menu: menu)),
                  );
                } else if (index == 1) {
                  // Điều hướng đến trang thêm menu
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddMenuItemPage(shop: widget.shop, menu: menu)),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                      color: AppColors.signIn,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 3,
                        color: AppColors.backgroundOrange,
                      )),
                  child: Center(
                    child: Text(
                      items[index],
                      style: AppTypography.textMd.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: AppColors.backgroundOrange,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final ShopModel shop;

  const HistoryPage({super.key, required this.shop});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List card = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shop_name', isEqualTo: widget.shop.shopName)
          .get();

      setState(() {
        card = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return [
            data['buyer_name'] ?? 'Unknown',
            data['order_name'] ?? 'Unknown',
            data['price']?.toString() ?? '0',
            data['date'] ?? 'Unknown',
            data['img'] ?? 'Unknown',
            data['rating'] ?? 0.0,
            data['review'] ?? '',
          ];
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching orders: $e';
        isLoading = false;
      });
      print('Error fetching orders: $e');
    }
  }

  void _showReviewDialog(BuildContext context, String review) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Review',
            style: TextStyle(
              color: AppColors.backgroundOrange,
            ),
          ),
          content: Text(review),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppColors.backgroundOrange,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order History",
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange)),
        backgroundColor: AppColors.backgroundYellow,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.backgroundOrange,
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const UserType())),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thẻ thông tin cửa hàng hoặc bất kỳ widget nào bạn muốn hiển thị
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.backgroundOrange, width: 2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(20))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.pin_drop_rounded,
                                      size: 25,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(widget.shop.shopName.toUpperCase(),
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.timelapse_rounded,
                                        size: 25),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                        "${widget.shop.openingTime} AM TO ${widget.shop.closingTime} PM",
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_cart, size: 25),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text("${card.length} ITEMS IN STOCK",
                                        style: AppTypography.textMd.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                // Container(
                                //     width: 30,
                                //     padding: const EdgeInsets.all(2),
                                //     decoration: BoxDecoration(
                                //         borderRadius: BorderRadius.circular(5),
                                //         color: AppColors.signIn),
                                //     child: Row(
                                //       children: [
                                //         Text(
                                //           "0",
                                //           style: AppTypography.textSm.copyWith(
                                //               fontSize: 15,
                                //               fontWeight: FontWeight.w700),
                                //         ),
                                //         const Icon(
                                //           Icons.star,
                                //           size: 15,
                                //         )
                                //       ],
                                //     )
                                //     )
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          "All Orders",
                          style: AppTypography.textMd.copyWith(
                              fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      card.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                "No orders found",
                                style: AppTypography.textMd.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: card.length,
                              itemBuilder: (context, index) {
                                final order = card[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFF2E0),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 15, 0, 0),
                                                  child: Text(
                                                      "User : ${order[0]}",
                                                      style: AppTypography
                                                          .textSm
                                                          .copyWith(
                                                              fontSize: 14)),
                                                ),
                                                Text(
                                                  "Order : ${order[1]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Text(
                                                  "Price : ${order[2]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Text(
                                                  "Time : ${order[3]}",
                                                  style: AppTypography.textSm
                                                      .copyWith(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400),
                                                ),
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius:
                                                          15, // Điều chỉnh bán kính để phù hợp với kích thước icon
                                                      backgroundColor: const Color(
                                                          0xFFFFF2E0), // Màu nền
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.comment,
                                                          size:
                                                              15, // Kích thước biểu tượng
                                                          color: Colors
                                                              .grey, // Màu biểu tượng
                                                        ),
                                                        onPressed: () =>
                                                            _showReviewDialog(
                                                                context,
                                                                order[6]),
                                                      ),
                                                    ),
                                                    RatingBarIndicator(
                                                      rating:
                                                          order[5].toDouble(),
                                                      itemBuilder:
                                                          (context, _) => Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                      ),
                                                      itemCount: 5,
                                                      itemSize: 20.0,
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Container(
                                            height: 120,
                                            width: 120,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: AppColors
                                                        .backgroundOrange,
                                                    width: 1.5),
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Image.network(
                                                order[4],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Image.asset(
                                                    'assets/iconshop.jpg',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
      // Nếu bạn muốn cuộn lên đầu khi có nhiều nội dung, hãy xem xét sử dụng ListView thay vì SingleChildScrollView với Column
    );
  }
}

class InfoPage extends StatefulWidget {
  final ShopModel shop;

  const InfoPage({super.key, required this.shop});

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late TextEditingController ownerNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController shopNameController;
  late TextEditingController openingTimeController;
  late TextEditingController closingTimeController;
  late TextEditingController upiIdController;

  bool _isEditable = false;
  bool _isUpdating = false;
  String _updateMessage = '';
  bool _showMessage = false;
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    ownerNameController = TextEditingController(text: widget.shop.ownerName);
    phoneNumberController =
        TextEditingController(text: widget.shop.phoneNumber);
    shopNameController = TextEditingController(text: widget.shop.shopName);
    openingTimeController =
        TextEditingController(text: widget.shop.openingTime);
    closingTimeController =
        TextEditingController(text: widget.shop.closingTime);
    upiIdController = TextEditingController(text: widget.shop.upiId);
    fetchWeather();
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    phoneNumberController.dispose();
    shopNameController.dispose();
    openingTimeController.dispose();
    closingTimeController.dispose();
    upiIdController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=Hanoi&appid=e0ea7c2430957c0b90c7a6375a5f8cba&units=metric',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Future<void> updateShop() async {
    setState(() {
      _isUpdating = true;
      _updateMessage = '';
      _showMessage = false;
    });

    try {
      // Tìm kiếm document dựa trên điều kiện
      final shopQuery = FirebaseFirestore.instance
          .collection('shop')
          .where('shop_id', isEqualTo: widget.shop.shopID);

      // Lấy snapshot của document
      final querySnapshot = await shopQuery.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Giả sử bạn muốn cập nhật document đầu tiên tìm thấy
        final shopRef = querySnapshot.docs.first.reference;

        await shopRef.update({
          'owner_name': ownerNameController.text,
          'phone_number': phoneNumberController.text,
          'shop_name': shopNameController.text,
          'opening_time': openingTimeController.text,
          'closing_time': closingTimeController.text,
          'upi_id': upiIdController.text,
        });

        setState(() {
          _updateMessage = 'Shop information updated successfully!';
          _isEditable = false;
          _showMessage = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            _showMessage = false; // Ẩn thông báo
          });
        });
      } else {
        setState(() {
          _updateMessage = "Error : No shop found .";
          _showMessage = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            _showMessage = false; // Ẩn thông báo
          });
        });
      }
    } catch (e) {
      setState(() {
        _updateMessage = 'Error updating shop: $e';
        _showMessage = true;
      });
      print('Error updating shop: $e');
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  IconData _getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_cloudy;
    }
  }

  void logOut() {
    // Xử lý đăng xuất tại đây, ví dụ: xóa thông tin đăng nhập, xóa token, v.v.
    // Sau đó chuyển đến màn hình đăng nhập
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              const LoginScreen()), // Đảm bảo LoginIn được import
    );
  }

  Widget inputText(TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 250,
        child: TextFormField(
          decoration: InputDecoration(
            enabledBorder: const OutlineInputBorder(
              borderSide:
                  BorderSide(width: 2, color: Color.fromRGBO(238, 118, 0, 1)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            focusedBorder: const OutlineInputBorder(
              // Đổi thành OutlineInputBorder để giữ viền khi có focus
              borderSide:
                  BorderSide(width: 2, color: Color.fromRGBO(238, 118, 0, 1)),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            hintText: hintText,
            suffixIcon: IconButton(
              icon: Icon(
                Icons.edit,
                color: _isEditable
                    ? Colors.grey[400]
                    : const Color.fromRGBO(238, 118, 0, 1),
              ),
              onPressed: () {
                setState(() {
                  _isEditable = !_isEditable;
                });
              },
            ),
          ),
          readOnly: !_isEditable,
          controller: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile",
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange)),
        backgroundColor: AppColors.backgroundYellow,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.backgroundOrange,
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const UserType())),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: AppColors.backgroundYellow,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20)),
                      color: Colors.amber[900]),
                ),
                Container(
                  height: 500,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20)),
                      color: Colors.white),
                ),
              ],
            ),
            //   Align(
            //   alignment: Alignment.topCenter,
            //   child: Container(
            //     margin: const EdgeInsets.only(top: 5),
            //     child: Column(
            //       children: [
            //         Text(
            //           "CAMPUS MEAL",
            //           style: TextStyle(
            //             fontSize: 16.5,
            //             fontWeight: FontWeight.bold,
            //             color: Colors.white,
            //           ),
            //         ),
            //         // if (weatherData != null)
            //         //   Row(
            //         //     mainAxisAlignment: MainAxisAlignment.center,
            //         //     children: [
            //         //       Icon(
            //         //         _getWeatherIcon(weatherData!['weather'][0]['main']),
            //         //         color: const Color.fromARGB(255, 58, 179, 234),
            //         //         size: 20,
            //         //       ),
            //         //       const SizedBox(width: 5),
            //         //       // Text(
            //         //       //   'Hà Nội: ${weatherData!['main']['temp']}°C, ',
            //         //       //   style: const TextStyle(
            //         //       //       fontSize: 16.5, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
            //         //       // ),
            //         //       // Text(
            //         //       //   weatherData!['weather'][0]['description'],
            //         //       //   style: const TextStyle(fontSize: 16.5, color: Color.fromARGB(255, 0, 0, 0)),
            //         //       // ),
            //         //     ],
            //         //   )
            //         // else
            //         //   const CircularProgressIndicator(),
            //       ],
            //     ),
            //   ),
            // ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 50),
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Color.fromRGBO(122, 103, 238, 1), width: 3),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    "assets/iconprofile.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 45,
              left: (MediaQuery.of(context).size.width - 250) /
                  2, // Căn giữa form
              child: Column(
                children: [
                  inputText(ownerNameController, "Owner Name"),
                  inputText(phoneNumberController, "Phone Number"),
                  inputText(shopNameController, "Shop Name"),
                  inputText(openingTimeController, "Opening Time"),
                  inputText(closingTimeController, "Closing Time"),
                  inputText(upiIdController, "UPI ID"),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left:
                  (MediaQuery.of(context).size.width - 300) / 2, // Căn giữa nút
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isUpdating
                        ? null
                        : () {
                            if (_isEditable) {
                              updateShop();
                            }
                          },
                    child: Container(
                      width: 100,
                      height: 45,
                      decoration: const BoxDecoration(
                          color: Color.fromRGBO(238, 118, 0, 1),
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Center(
                        child: _isUpdating
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                "UPDATE",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      logOut();
                    },
                    child: Container(
                      width: 100,
                      height: 45,
                      decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Center(
                        child: Text(
                          "LOG OUT",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  // Nút CHAT
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BuyerSelectionScreen(
                                shop: widget
                                    .shop)), // Điều hướng tới màn hình chat
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 45,
                      decoration: const BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Center(
                        child: Text(
                          "CHAT",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showMessage && _updateMessage.isNotEmpty)
              Positioned(
                bottom: 570, // Điều chỉnh lên một chút để không đè lên chữ
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _updateMessage.contains('Error')
                        ? Colors.redAccent
                        : Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _updateMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SellerHomeScreen extends StatefulWidget {
  final ShopModel shop;

  const SellerHomeScreen({super.key, required this.shop});

  @override
  _SellerHomeScreenState createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  List<Widget> _widgetOptions = [];

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      HomePage(shop: widget.shop),
      HistoryPage(shop: widget.shop),
      ntfPage(),
      InfoPage(shop: widget.shop),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Khi nhấn nút QR, mở màn hình QRScanner
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Scanner()),
      );
    } else {
      // Cập nhật trang hiện tại cho các mục khác
      setState(() {
        _selectedIndex = index < 2 ? index : index - 1;
      });
      _pageController.jumpToPage(_selectedIndex);
    }
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: PageView(
  //       controller: _pageController,
  //       onPageChanged: (index) {
  //         setState(() {
  //           _selectedIndex = index;
  //         });
  //       },
  //       children: _widgetOptions,
  //     ),
  //     bottomNavigationBar: Theme(
  //       data: Theme.of(context).copyWith(
  //         canvasColor: AppColors.backgroundYellow,
  //       ),
  //       child: BottomNavigationBar(
  //         items: List.generate(4, (index) {
  //           return BottomNavigationBarItem(
  //             icon: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(
  //                   index == 0
  //                       ? Icons.home_outlined
  //                       : index == 1
  //                           ? Icons.history
  //                           : index == 2
  //                               ? Icons.notifications
  //                               : Icons.account_circle_outlined,
  //                   color: _selectedIndex == index ? AppColors.backgroundOrange : Colors.grey,
  //                 ),
  //                 Text(
  //                   index == 0
  //                       ? 'Home'
  //                       : index == 1
  //                           ? 'History'
  //                           : index == 2
  //                               ? 'Notifications'
  //                               : 'Profile',
  //                   style: TextStyle(
  //                     color: _selectedIndex == index ? AppColors.backgroundOrange : Colors.grey,
  //                     fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             label: '',
  //           );
  //         }),
  //         currentIndex: _selectedIndex,
  //         selectedItemColor: AppColors.backgroundOrange,
  //         unselectedItemColor: Colors.grey,
  //         type: BottomNavigationBarType.fixed,
  //         onTap: (index) {
  //           _onItemTapped(index);
  //           setState(() {});
  //         },
  //         elevation: 0,
  //         selectedFontSize: 0.5,
  //         unselectedFontSize: 0.5,
  //       ),
  //     ),
  //   );
  // }

  void showEditDialog(BuildContext context, String notificationId,
      String initialTitle, String initialDescription) {
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _descriptionController =
        TextEditingController();

    // Thiết lập giá trị ban đầu
    _titleController.text = initialTitle;
    _descriptionController.text = initialDescription;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Edit Notification",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 254, 181, 122),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton(
                          icon: Text('🔔', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🔔';
                          },
                        ),
                        IconButton(
                          icon: Text('📢', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '📢';
                          },
                        ),
                        IconButton(
                          icon: Text('💡', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '💡';
                          },
                        ),
                        IconButton(
                          icon: Text('⭐', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '⭐';
                          },
                        ),
                        IconButton(
                          icon: Text('⚠️', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '⚠️';
                          },
                        ),
                        IconButton(
                          icon: Text('💸', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '💸';
                          },
                        ),
                        IconButton(
                          icon: Text('🎉', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🎉';
                          },
                        ),
                        IconButton(
                          icon: Text('🔥', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🔥';
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: "Title",
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(
                          color: CupertinoColors.systemGrey4, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16),
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                  SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _descriptionController,
                    placeholder: "Description",
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(
                          color: CupertinoColors.systemGrey4, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16),
                    style: TextStyle(color: CupertinoColors.black),
                    maxLines: 4,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      updateNotification(
                        notificationId,
                        _titleController.text,
                        _descriptionController.text,
                      );
                      Navigator.of(context).pop(); // Đóng hộp thoại
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Update",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void updateNotification(String id, String title, String description) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({
      'title': title,
      'description': description,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? AppColors.backgroundOrange
                      : Colors.grey,
                ),
                Text(
                  'Home',
                  style: TextStyle(
                    color: _selectedIndex == 0
                        ? AppColors.backgroundOrange
                        : Colors.grey,
                    fontWeight: _selectedIndex == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  color: _selectedIndex == 1
                      ? AppColors.backgroundOrange
                      : Colors.grey,
                ),
                Text(
                  'History',
                  style: TextStyle(
                    color: _selectedIndex == 1
                        ? AppColors.backgroundOrange
                        : Colors.grey,
                    fontWeight: _selectedIndex == 1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications,
                  color: _selectedIndex == 2
                      ? AppColors.backgroundOrange
                      : Colors.grey,
                ),
                Text(
                  'Notices',
                  style: TextStyle(
                    color: _selectedIndex == 2
                        ? AppColors.backgroundOrange
                        : Colors.grey,
                    fontWeight: _selectedIndex == 2
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: _selectedIndex == 3
                      ? AppColors.backgroundOrange
                      : Colors.grey,
                ),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: _selectedIndex == 3
                        ? AppColors.backgroundOrange
                        : Colors.grey,
                    fontWeight: _selectedIndex == 3
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.backgroundOrange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        elevation: 0,
      ),
    );
  }

  Widget ntfPage() {
    return Scaffold(
      backgroundColor: AppColors.backgroundYellow,
      appBar: AppBar(
        title: Text("Notifications",
            style: AppTypography.textMd.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.backgroundOrange)),
        backgroundColor: AppColors.backgroundYellow,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.backgroundOrange,
          ),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const UserType())),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: AppColors.backgroundOrange,
            ),
            // onPressed: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => createNotificationForm()),
            //   );
            // },
            onPressed: () {
              showCreateNotificationDialog(context); // Gọi hàm mở hộp thoại
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('shop_id', isEqualTo: widget.shop.shopID)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No notifications available'));
                }
                final notifications = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final data =
                        notifications[index].data() as Map<String, dynamic>;
                    return ntfcard(
                      data['title'] ?? 'No Title',
                      data['description'] ?? 'No Description',
                      data['date'] ?? 'Unknown Date',
                      isNew: data['isNew'] ?? false,
                      onEdit: () {
                        showEditDialog(
                          context,
                          notifications[index].id,
                          data['title'],
                          data['description'],
                        );
                      },
                      onDelete: () {
                        FirebaseFirestore.instance
                            .collection('notifications')
                            .doc(notifications[index].id)
                            .delete();
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Received Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: fakeNotifications.length,
              itemBuilder: (context, index) {
                final fakeData = fakeNotifications[index];
                return ntfcard(
                  fakeData['title'] ?? 'No Title',
                  fakeData['description'] ?? 'No Description',
                  fakeData['date'] ?? 'Unknown Date',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, String>> fakeNotifications = [
    {
      "title": "Đơn hàng từ Khách hàng Khoa",
      "description": "Khách hàng A đã đặt hàng với mã: #1001.",
      "date": "01/10/2024",
    },
    {
      "title": "Đơn hàng từ Khách hàng Nam",
      "description": "Khách hàng B đã đặt hàng với mã: #1002.",
      "date": "02/10/2024",
    },
    {
      "title": "Đơn hàng từ Khách hàng Tuấn",
      "description": "Khách hàng C đã đặt hàng với mã: #1003.",
      "date": "01/10/2024",
    },
  ];

  Widget ntfcard(
    String title,
    String description,
    String date, {
    bool isNew = false, // Tham số để xác định xem thông báo có mới hay không
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 145, 0),
                        ),
                      ),
                      if (isNew) // Kiểm tra xem có là thông báo mới không
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Nút chỉnh sửa nếu có
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            // Nút xóa nếu có
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Hiện hộp thoại xác nhận trước khi xóa
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Xác nhận xóa'),
                        content: Text(
                            'Bạn có chắc chắn muốn xóa thông báo này không?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Đóng hộp thoại
                            },
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (onDelete != null) onDelete(); // Gọi hàm xóa
                              Navigator.of(context).pop(); // Đóng hộp thoại
                            },
                            child: Text('Xóa'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void showCreateNotificationDialog(BuildContext context) {
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Create Notification",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 254, 181, 122),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton(
                          icon: Text('🔔', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🔔';
                          },
                        ),
                        IconButton(
                          icon: Text('📢', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '📢';
                          },
                        ),
                        IconButton(
                          icon: Text('💡', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '💡';
                          },
                        ),
                        IconButton(
                          icon: Text('⭐', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '⭐';
                          },
                        ),
                        IconButton(
                          icon: Text('⚠️', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '⚠️';
                          },
                        ),
                        IconButton(
                          icon: Text('💸', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '💸';
                          },
                        ),
                        IconButton(
                          icon: Text('🎉', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🎉';
                          },
                        ),
                        IconButton(
                          icon: Text('🔥', style: TextStyle(fontSize: 24)),
                          onPressed: () {
                            _titleController.text += '🔥';
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: "Title",
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(
                          color: CupertinoColors.systemGrey4, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16),
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                  SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _descriptionController,
                    placeholder: "Description",
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(
                          color: CupertinoColors.systemGrey4, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16),
                    style: TextStyle(color: CupertinoColors.black),
                    maxLines: 4,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      createNotification(
                        _titleController.text,
                        _descriptionController.text,
                      );
                      Navigator.of(context).pop(); // Đóng hộp thoại
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF80CBC4),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Create",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void createNotification(String title, String description) async {
    CollectionReference notifications =
        FirebaseFirestore.instance.collection('notifications');

    await notifications.add({
      'title': title,
      'description': description,
      'date': DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now()),
      'shop_id': widget.shop.shopID,
      'isNew': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification created successfully!')),
    );
  }
}

class OrderTile extends StatelessWidget {
  final String buyerPhone;
  final String buyerName;
  final String txnId;
  final String status;
  final int totalAmount;

  const OrderTile({
    Key? key,
    required this.buyerName,
    required this.buyerPhone,
    required this.status,
    required this.totalAmount,
    required this.txnId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.signIn,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                buyerPhone,
                style: AppTypography.textMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                buyerName,
                style: AppTypography.textMd.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildActionButton(
                      "CONFIRM", AppColors.backgroundOrange, Colors.white),
                  const SizedBox(width: 8),
                  _buildActionButton(
                      "REJECT", AppColors.backgroundYellow, Colors.black),
                  const SizedBox(width: 8),
                  _buildActionButton(
                      "VIEW", AppColors.backgroundYellow, Colors.black),
                ],
              ),
              Text(
                "Rs. $totalAmount",
                textAlign: TextAlign.end,
                style: AppTypography.textMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTypography.textMd.copyWith(
          color: textColor,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }
}

class EditNotificationForm extends StatefulWidget {
  final String notificationId;
  final String initialTitle;
  final String initialDescription;

  const EditNotificationForm({
    Key? key,
    required this.notificationId,
    required this.initialTitle,
    required this.initialDescription,
  }) : super(key: key);

  @override
  _EditNotificationFormState createState() => _EditNotificationFormState();
}

class _EditNotificationFormState extends State<EditNotificationForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
    _descriptionController.text = widget.initialDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Notification"),
        backgroundColor: const Color.fromARGB(255, 254, 181, 122),
      ),
      body: Container(
        color: Colors.white, // Màu nền chính
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: SingleChildScrollView(
              // Cho phép cuộn nếu cần thiết
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Title",
                      labelStyle:
                          TextStyle(color: Colors.black54), // Màu chữ label
                      border: OutlineInputBorder(), // Viền ô nhập
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.amber,
                            width: 2.0), // Màu viền khi có tiêu điểm
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle:
                          TextStyle(color: Colors.black54), // Màu chữ label
                      border: OutlineInputBorder(), // Viền ô nhập
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.amber,
                            width: 2.0), // Màu viền khi có tiêu điểm
                      ),
                    ),
                    maxLines: 4, // Cho phép nhiều dòng
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      updateNotification(widget.notificationId,
                          _titleController.text, _descriptionController.text);
                      Navigator.pop(context); // Quay lại trang trước
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 207, 236, 125), // Màu nền của nút
                      padding:
                          EdgeInsets.symmetric(vertical: 15), // Padding cho nút
                    ),
                    child: Text("Update",
                        style:
                            TextStyle(fontSize: 16)), // Kích thước chữ lớn hơn
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm cập nhật thông báo trong Firestore
  void updateNotification(String id, String title, String description) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({
      'title': title,
      'description': description,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification updated successfully!')),
    );
  }
}
