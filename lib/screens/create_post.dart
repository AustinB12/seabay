import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'homepage.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String errorMessage = '';
  String successMessage = '';

  final db = DbService();

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final price = (double.tryParse(_priceController.text) ?? 0.0).toInt();

    if (title.isEmpty || description.isEmpty || price == 0) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    final newPost = Post(
      title: title,
      description: description,
      price: price,
      isActive: true, // Default value (active post)
      userId: db.getCurrentUserId() as String,
    );

    try {
      await db.createPost(newPost);
      //Navigator.pop(context);
      // setState(() {
      //   errorMessage = '';
      //   successMessage = 'Post made successfully! ';
      // });
      if (context.mounted){
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage())
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to create post. $e';
      });
    }
  }

  void goToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createPost,
              child: const Text('Create Post'),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
