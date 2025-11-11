import 'package:cloud_firestore/cloud_firestore.dart';
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
      appBar: AppBar(
        actions: [
          GestureDetector(
            child: Icon(Icons.exit_to_app),
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
              child: Text('Logged in as  '),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: TextField(
              controller: _updateLastController,
              decoration: InputDecoration(
                hintText: 'Last name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                fillColor: Color.fromARGB(183, 255, 255, 255),
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
                      style: TextStyle(
                        fontSize: 18,
                        color: const Color.fromARGB(181, 76, 175, 79),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal:45 ,vertical: 50),
                  ));
                  /*await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user)
                      .update({'last name': _updateLastController.text.trim()});

                      await FirebaseFirestore.instance.collection('users').doc(Uer).update({
                        'last name': _updateLastController.text.trim()
                      });

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      'Succesful',
                      style: TextStyle(color: Colors.black),
                    ),
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                  )); */
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                child: Text('Update'),
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
