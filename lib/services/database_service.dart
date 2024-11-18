import 'package:campus_catalogue/models/buyer_model.dart';
import 'package:campus_catalogue/models/item_model.dart';
import 'package:campus_catalogue/models/order_model.dart';
import 'package:campus_catalogue/models/shopModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  addBuyer(Buyer employeeData) async {
    await _db.collection("Buyer").add(employeeData.toMap());
  }

  addToCart(ItemModel employeeData) async {
    _db
        .collection("Buyer")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection("cart_items")
        .add(employeeData.toMap());
    await _db.collection("cart_items").add(employeeData.toMap());
  }

  addShop(ShopModel employeeData) async {
    Set s = {};

    for (int i = 0; i < employeeData.menu.length; i++) {
      // s = s+ employeeData.menu['name'];
      s.addAll(employeeData.menu[i]['name'].toString().split(' '));
    }
    s.addAll(employeeData.location.toString().split(' '));
    s.addAll(employeeData.shopName.toString().split(' '));

    DocumentReference docref =
        await _db.collection("shop").add(employeeData.toMap());

    List a = s.toList();
    for (int i = 0; i < a.length; i++) {
      var p = await _db.collection('cache').doc(a[i]).get();
      if (p.exists) {
        _db.collection('cache').doc(a[i]).set({
          'list': FieldValue.arrayUnion([docref.id])
        });
      } else {
        _db.collection('cache').add({
          a[i]: [docref.id]
        });
      }
    }

    print(employeeData);
  }

  Future<List> retrieveBuyer() async {
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await _db.collection("Buyer").get();
    return snapshot.docs
        .map((docSnapshot) => Buyer.fromDocumentSnapshot(docSnapshot))
        .toList();
  }

  Future<List<ItemModel>> retrieveCart() async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection("Buyer")
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection("cart_items")
        .get();
    return snapshot.docs
        .map((docSnapshot) => ItemModel.fromDocumentSnapshot(docSnapshot))
        .toList();
  }

  Future<List<OrderModel>> retrieveOrders(shopId) async {
    QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection("orders")
        .where("shop_id", isEqualTo: shopId)
        .get();
    return snapshot.docs
        .map((docSnapshot) => OrderModel.fromDocumentSnapshot(docSnapshot))
        .toList();
  }

  // Future<List<Map<String, dynamic>>> getOrders(String buyerName) async {
  //   List<Map<String, dynamic>> orders = [];

  //   try {
  //     // Giả sử bạn lấy tất cả tài liệu trong bộ sưu tập "buy"
  //     QuerySnapshot buySnapshot = await _db
  //         .collection('buy')
  //         .where('buyer_name', isEqualTo: buyerName)
  //         .get();

  //     for (var buyDoc in buySnapshot.docs) {
  //       // Giả sử "orders" là một mảng trong tài liệu
  //       List<dynamic> ordersList = buyDoc['orders'];

  //       for (var order in ordersList) {
  //         orders.add({
  //           'buyer_name': order['buyer_name'],
  //           'buyer_phone': order['buyer_phone'],
  //           'shop_name': order['shop_name'],
  //           'date': order['date'],
  //           'name': order['order_name'],
  //           'price': order['price'],
  //           'imgUrl': order['img'],
  //           'count': order['count'],
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print("Error fetching orders: $e");
  //   }

  //   return orders;
  // }
  Stream<List<Map<String, dynamic>>> getOrders(String buyerName) {
    return _db
        .collection('buy')
        .where('buyer_name', isEqualTo: buyerName)
        .snapshots() // Lấy dữ liệu theo dạng Stream
        .map((snapshot) {
      List<Map<String, dynamic>> orders = [];

      for (var buyDoc in snapshot.docs) {
        List<dynamic> ordersList = buyDoc['orders'];

        for (var order in ordersList) {
          orders.add({
            'buyer_name': order['buyer_name'],
            'buyer_phone': order['buyer_phone'],
            'shop_name': order['shop_name'],
            'date': order['date'],
            'name': order['order_name'],
            'price': order['price'],
            'imgUrl': order['img'],
            'count': order['count'],
          });
        }
      }
      return orders;
    });
  }

  // Future<void> updateOrdersQuantities(
  //     List<Map<String, dynamic>> items, List<int> quantities) async {
  //   for (var i = 0; i < items.length; i++) {
  //     // Tìm buyer
  //     QuerySnapshot buyQuery = await FirebaseFirestore.instance
  //         .collection('buy') // Collection 'buy'
  //         .get(); // Lấy tất cả các buyers

  //     if (buyQuery.docs.isNotEmpty) {
  //       // Duyệt qua từng buyer tìm được
  //       for (var buyDoc in buyQuery.docs) {
  //         // Lấy danh sách orders của buyer
  //         List<dynamic> orders = List.from(buyDoc['orders']);

  //         // Tìm và cập nhật order tương ứng với quantity từ items[i]
  //         for (var j = 0; j < orders.length; j++) {
  //           // Giả định rằng mỗi order có các trường 'order_name' và 'shop_name'
  //           // Cập nhật 'count' chỉ nếu order tương ứng với items[i]
  //           if (orders[j]['order_name'] == items[i]['order_name'] &&
  //               orders[j]['shop_name'] == items[i]['shop_name']) {
  //             // Cập nhật 'count' cho order tương ứng
  //             orders[j]['count'] = quantities[i];
  //             break; // Dừng vòng lặp sau khi cập nhật
  //           }
  //         }

  //         // Cập nhật lại danh sách orders cho buyer nếu có thay đổi
  //         await buyDoc.reference.update({'orders': orders});
  //       }
  //     }
  //   }
  // }

  // Future<void> updateOrdersQuantities(List<Map<String, dynamic>> items,
  //     List<num> quantities, String buyerName) async {
  //   for (var i = 0; i < items.length; i++) {
  //     // Tìm buyer dựa trên điều kiện phù hợp nếu có
  //     QuerySnapshot buyQuery = await FirebaseFirestore.instance
  //         .collection('buy')
  //         .where('buyer_name', isEqualTo: buyerName)
  //         // Collection 'buy'
  //         .get(); // Lấy tất cả các buyers hoặc có điều kiện khác nếu cần
  //     int index = 0;

  //     if (buyQuery.docs.isNotEmpty) {
  //       // Duyệt qua từng buyer tìm được
  //       for (var buyDoc in buyQuery.docs) {
  //         // Lấy danh sách orders của buyer
  //         List<dynamic> orders = List.from(buyDoc['orders']);

  //         // Cập nhật order tương ứng với quantity từ items[i]
  //         for (var j = 0; j < orders.length; j++) {
  //           // Cập nhật 'count' cho mỗi order dựa vào quantities[i]
  //           orders[j]['count'] = quantities[index];
  //         }

  //         // Cập nhật lại toàn bộ danh sách orders cho buyer
  //         await buyDoc.reference.update({'orders': orders});
  //         index++;
  //       }
  //     }
  //   }
  // }

  Future<void> updateOrdersQuantities(List<Map<String, dynamic>> items,
      List<num> quantities, String buyerName) async {
    for (var i = 0; i < items.length; i++) {
      // Tìm buyer dựa trên điều kiện phù hợp nếu có
      QuerySnapshot buyQuery = await FirebaseFirestore.instance
          .collection('buy')
          .where('buyer_name', isEqualTo: buyerName)
          // Collection 'buy'
          .get(); // Lấy tất cả các buyers hoặc có điều kiện khác nếu cần
      int index = 0;

      if (buyQuery.docs.isNotEmpty) {
        // Duyệt qua từng buyer tìm được
        for (var buyDoc in buyQuery.docs) {
          // Lấy danh sách orders của buyer
          List<dynamic> orders = List.from(buyDoc['orders']);

          // Cập nhật order tương ứng với quantity từ items[i]
          for (var j = 0; j < orders.length; j++) {
            // Cập nhật 'count' cho mỗi order dựa vào quantities[i]
            orders[j]['count'] = quantities[index];
          }

          // Cập nhật lại toàn bộ danh sách orders cho buyer
          await buyDoc.reference.update({'orders': orders});
          index++;
        }
      }
    }
  }

  // Future<void> updateOrdersQuantities(
  //     List<Map<String, dynamic>> items, List<num> quantities) async {
  //   for (var i = 0; i < items.length; i++) {
  //     // Tìm buyer dựa trên điều kiện phù hợp nếu có
  //     QuerySnapshot buyQuery = await FirebaseFirestore.instance
  //         .collection('buy')
  //         .get(); // Lấy tất cả các buyers hoặc có điều kiện khác nếu cần

  //     int index = 0;

  //     if (buyQuery.docs.isNotEmpty) {
  //       // Duyệt qua từng buyer tìm được
  //       for (var buyDoc in buyQuery.docs) {
  //         // Lấy danh sách orders của buyer
  //         List<dynamic> orders = List.from(buyDoc['orders']);

  //         // Cập nhật order tương ứng với quantity từ items[i]
  //         for (var j = 0; j < orders.length; j++) {
  //           if (index < quantities.length) {
  //             // Cập nhật 'count' cho mỗi order dựa vào quantities[index]
  //             orders[j]['count'] = quantities[i];
  //           } else {
  //             // Xử lý khi index vượt quá độ dài của quantities
  //             print('Index $index vượt quá danh sách quantities.');
  //             // Bạn có thể đặt giá trị mặc định hoặc bỏ qua việc cập nhật
  //             orders[j]['count'] =
  //                 orders[j]['count'] ?? 1; // Đặt mặc định là 1 nếu không có
  //           }
  //         }

  //         // Cập nhật lại toàn bộ danh sách orders cho buyer
  //         await buyDoc.reference.update({'orders': orders});
  //         // index++;
  //       }
  //     } else {
  //       print('Không tìm thấy buyer nào trong collection "buy".');
  //     }
  //   }
  // }

  Future<void> deleteOrder(String buyerName, String orderName) async {
    // Truy cập đến collection 'buy'
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('buy')
        .where('buyer_name', isEqualTo: buyerName)
        .get();

    // Lặp qua từng document trong 'buy'
    for (var doc in snapshot.docs) {
      // Lấy danh sách orders từ từng buyer
      List orders = doc['orders'] ?? [];

      // Tìm chỉ số của order cần xóa
      int orderIndex =
          orders.indexWhere((order) => order['order_name'] == orderName);
      if (orderIndex != -1) {
        // Xóa order khỏi danh sách orders
        orders.removeAt(orderIndex);

        // Kiểm tra xem orders có còn lại không
        if (orders.isEmpty) {
          // Nếu orders trống, xóa tài liệu buy
          await doc.reference.delete();
        } else {
          // Nếu còn order, cập nhật lại document
          await doc.reference.update({'orders': orders});
        }
      }
    }
  }
  // Future<void> deleteOrder(String buyerName, String itemId) async {
  //   // Xóa tài liệu từ Firestore
  //   await _db
  //       .collection('buy')
  //       .doc(buyerName) // Hoặc đường dẫn đến tài liệu cụ thể
  //       .update({
  //     'orders': FieldValue.arrayRemove(
  //         [itemId]) // Giả định bạn đang lưu ID trong danh sách 'orders'
  //   });
  // }
}
