import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:seabay_app/api/db_service.dart';
import 'package:seabay_app/api/posts.dart';
import 'package:seabay_app/api/storage_service.dart';
import 'package:seabay_app/auth/auth.dart';
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

  final List<XFile> _imageFiles = [];

  final db = DbService();
  final storage = StorageService();
  final postsDB = PostsService();
  final auth = AuthService();

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final inputPrice = _priceController.text.trim().replaceAll(',', '');
    final priceParsed = double.tryParse(inputPrice);

    if (title.isEmpty || description.isEmpty || inputPrice == 0) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (priceParsed == null) {
      setState(() {
        errorMessage = 'Price must be a number.';
        successMessage = '';
      });
      return;
    }
    final price = priceParsed.toInt();

    final newPost = Post(
      title: title,
      description: description,
      price: price,
      isActive: true,
      userId: auth.getCurrentUserId() as String,
      imageUrls:
          postImgUrl != null && postImgUrl!.isNotEmpty ? [postImgUrl!] : [],
    );

    try {
      final createdPost = await postsDB.createPost(newPost);

      if (_imageFiles.isNotEmpty) {
        List<String> publicImageUrls = [];
        _imageFiles.forEach((img) async {
          String imageExtension = img.path.split('.').last.toLowerCase();
          var imageBytes = await img.readAsBytes();
          var newPostId = createdPost['data'][0]['id'];
          print('newPostId: $newPostId');
          var imagePath =
              '/$newPostId/${DateTime.now().millisecondsSinceEpoch.toString()}';
          await storage.uploadPostPicBucket(
              imagePath, imageBytes, imageExtension);
          String imageUrl = await storage.getPostImageUrl(imagePath);
          publicImageUrls.add(imageUrl);
        });

        // Update the post record with the list of image urls
        postsDB.updatePost(Post(
            isActive: newPost.isActive,
            title: newPost.title,
            userId: newPost.userId,
            description: newPost.description,
            id: newPost.id,
            imageUrls: publicImageUrls,
            price: newPost.price));
      }

      Navigator.pop(context);
      setState(() {
        errorMessage = '';
        successMessage = 'Post created successfully!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text(successMessage))),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to create post. $e';
        successMessage = '';
      });
    }
  }

  void goToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  //? IMAGES STUFF

  String? postImgUrl = '';

  /// Pick an image to use in the listing
  Future pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }
    setState(() {
      // Add image to list of uploaded images
      _imageFiles.add(image);
    });

    final imageExtension = image.path.split('.').last.toLowerCase();
    final imageBytes = await image.readAsBytes();
    final userId = auth.getCurrentUserId();
    final imagePath =
        '/$userId/${DateTime.now().millisecondsSinceEpoch.toString()}';

    await storage.uploadPostPicBucket(imagePath, imageBytes, imageExtension);

    String imageUrl = await storage.getPostImageUrl(imagePath);

    setState(() {
      postImgUrl = imageUrl;
    });
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
                onPressed: () => pickImage(),
                child: const Text('Upload Image')),
            ElevatedButton(
              onPressed: _createPost,
              child: const Text('Create Post'),
            ),
            if (postImgUrl!.isNotEmpty) Image.network(postImgUrl!),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
