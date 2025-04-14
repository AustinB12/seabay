import 'package:flutter/material.dart';

class PostsList extends StatefulWidget {
  const PostsList({Key? key}) : super(key: key);

  @override
  PostsListState createState() => PostsListState();
}

class PostsListState extends State<PostsList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[200],
    );
  }
}
