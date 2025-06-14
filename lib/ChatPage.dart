import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Home/HomePage.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String ID;
  final String chatID;
  const ChatPage({super.key, required this.ID, required this.chatID});

  @override
  _ChatPage createState() => _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void send_message(){
    String message=_messageController.text;
    final String first = int.parse(widget.ID)>int.parse(widget.chatID)?widget.ID:widget.chatID;
    final String second = int.parse(widget.ID)<int.parse(widget.chatID)?widget.ID:widget.chatID;
    FirebaseFirestore.instance
        .collection("Chat")
        .doc("chat_${first}_${second}")
        .collection("MESSAGES")
        .add({
      "SENDER": widget.ID,
      "TEXT": message,
      "TIME": FieldValue.serverTimestamp()
    });
    FirebaseFirestore.instance
        .collection("Chat")
        .doc("chat_${first}_${second}")
        .update({
      "LAST": message,
      "LASTSENDER": widget.ID,
      "TIMESTAMP": FieldValue.serverTimestamp()// Deletes the 'LAST' field
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final String first = int.parse(widget.ID)>int.parse(widget.chatID)?widget.ID:widget.chatID;
    final String second = int.parse(widget.ID)<int.parse(widget.chatID)?widget.ID:widget.chatID;
    return Scaffold(
      appBar: AppBar(title: Text('Chat Messages')),
      body: Column(
        children: [
          SizedBox(
            height: 420,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Chat")
                  .doc("chat_${first}_${second}")
                  .collection("MESSAGES")
                  .orderBy("TIME", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages found"));
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                 itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var messageData = messages[index];

                    Timestamp timeStamp = messageData['TIME'];
                    String formattedTime = DateFormat('MMM d, hh:mm a').format(timeStamp.toDate());

                    return Row(
                      mainAxisAlignment: messageData['SENDER']==widget.ID?MainAxisAlignment.end:MainAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Text(messageData['SENDER']!=widget.ID?messageData['SENDER']:""),
                            Row(
                              children: [
                                if(messageData['SENDER']!=widget.ID) ...[
                                  Text(
                                    messageData['TEXT'],
                                    style: TextStyle(fontSize: 30, color: Colors.grey),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(fontSize: 10, color: Colors.black),
                                    ),
                                  ),
                                ]
                                else ...[
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Text(
                                      formattedTime,
                                      style: TextStyle(fontSize: 10, color: Colors.black),
                                    ),
                                  ),
                                  Text(
                                    messageData['TEXT'],
                                    style: TextStyle(fontSize: 30, color: Colors.grey),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                );
              },
            ),
          ),
          Stack(
            children: [
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 1,),
                  child: TextButton(
                    onPressed: (){
                      send_message();
                    },
                    style: TextButton.styleFrom(
                      shape: CircleBorder(),
                    ),
                    child: Text('S'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
