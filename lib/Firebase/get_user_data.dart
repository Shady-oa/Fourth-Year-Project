import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class GetUserData extends StatelessWidget {
  final String docId;
  const GetUserData({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    //get collection
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(docId).get(),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return Text(
            'First Name: ${data['first name']} ${data['last name']}',
            style: kTextTheme.bodyLarge,
          );
        }
        return Text('loading...', style: kTextTheme.bodyMedium);
      }),
    );
  }
}
