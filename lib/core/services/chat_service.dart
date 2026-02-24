import 'package:carvia/core/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deterministic chat ID: sorted participant IDs + vehicleId
  String chatId(String userId1, String userId2, String vehicleId) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}_$vehicleId';
  }

  /// Ensure the chat document exists, then return its ID
  Future<String> ensureChat({
    required String buyerId,
    required String buyerName,
    required String sellerId,
    required String sellerName,
    required String vehicleId,
    required String vehicleName,
  }) async {
    final cid = chatId(buyerId, sellerId, vehicleId);
    final ref = _firestore.collection('chats').doc(cid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [buyerId, sellerId],
        'buyerId': buyerId,
        'buyerName': buyerName,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    return cid;
  }

  Stream<List<MessageModel>> messagesStream(String cid) {
    return _firestore
        .collection('chats')
        .doc(cid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> sendMessage({
    required String cid,
    required String senderId,
    required String text,
  }) async {
    final chatRef = _firestore.collection('chats').doc(cid);
    await chatRef.collection('messages').add({
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    await chatRef.update({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }
}
