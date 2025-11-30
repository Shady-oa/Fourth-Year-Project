import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/constants.dart';
import 'package:final_project/get_user_data.dart';
// import 'package:firebase/get_user_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final docId = FirebaseAuth.instance.currentUser!.uid;

  final _updateLastController = TextEditingController();

  @override
  void dispose() {
    _updateLastController.dispose();
    super.dispose();
  }

  List docIds = [];
  Future getDocIds() async {
    await FirebaseFirestore.instance.collection('users').get().then(
          (snapshot) => snapshot.docs.forEach((documents) {
            //print(documents.reference);
            docIds.add(documents.reference.id);
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        backgroundColor: primaryText,
        actions: [
          GestureDetector(
            child: const Icon(Icons.exit_to_app, color: primaryBg),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SafeArea(
            child: Center(
              child: Text('Logged in as  ', style: kTextTheme.bodyLarge),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _updateLastController,
              decoration: InputDecoration(
                hintText: 'Last name',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                fillColor: primaryBg.withOpacity(0.8),
                filled: true,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextButton(
                onPressed: () async {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(docId)
                      .update({
                    'last name': _updateLastController.text.trim(),
                  });
                  _updateLastController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'update successful !!',
                      style: kTextTheme.bodyLarge?.copyWith(color: brandGreen),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 45, vertical: 50),
                  ));
                },
                style: TextButton.styleFrom(
                  backgroundColor: brandGreen,
                ),
                child: Text('Update',
                    style: kTextTheme.bodyMedium?.copyWith(color: primaryText)),
              ),
            ),
          ),
          Expanded(
              child: FutureBuilder(
                  future: getDocIds(),
                  builder: (context, index) {
                    return ListView.builder(
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: GetUserData(docId: docIds[index]),
                        );
                      },
                      itemCount: docIds.length,
                    );
                  })),
        ],
      ),
    );
  }
}
