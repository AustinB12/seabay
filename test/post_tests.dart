import 'package:seabay_app/api/posts.dart';
import 'package:test/test.dart';

final testValue = "im a description";

void main() {
  test('Should be able to update Post description', () {
    final post = Post(title: 'test', isActive: true, userId: '123');

    post.description = testValue;

    expect(post.description, testValue);
  });
}
