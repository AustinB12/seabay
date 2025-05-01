import 'package:seabay_app/api/posts.dart';
import 'package:test/test.dart';

final testValue = "im a different";

void main() {
  test('Should be able to update Post description', () {
    final post = Post(title: 'test', isActive: true, userId: '123');

    post.description = testValue;

    expect(post.description, testValue);
  });
  test('Should be able to update Post title', () {
    final post = Post(title: 'test', isActive: true, userId: '123');

    post.title = testValue;

    expect(post.title, testValue);
  });
}
