import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ChatPage.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  final String ID;
  const ChatListPage({super.key, required this.ID});

  @override
  _ChatListPage createState() => _ChatListPage();
}

class _ChatListPage extends State<ChatListPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Messages')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Chat")
            .where("PARTICIPANTS", arrayContains: widget.ID)
            .snapshots(),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No chats"));
          }

          var messages = snapshot.data!.docs;

           return ListView.builder(
             itemCount: messages.length,
             itemBuilder: (context,index){
               var message=messages[index];
               return ListTile(
                 title: Text(message['PARTICIPANTS'][0]==widget.ID?message['PARTICIPANTS'][1]:message['PARTICIPANTS'][0]),
                 subtitle: Text(message["LAST"]),
                 onTap: (){
                   Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(ID: widget.ID, chatID: message['PARTICIPANTS'][0]==widget.ID?message['PARTICIPANTS'][1]:message['PARTICIPANTS'][0])));
                 },
               );
             }
           );
        },
      ),
    );
  }
}
