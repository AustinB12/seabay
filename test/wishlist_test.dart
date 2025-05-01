import 'package:seabay_app/api/wishlists.dart';
import 'package:test/test.dart';

final testValue = "im a different";

void main() {
  test('Should be able to update Post description', () {
    final wl = WishList(id: 1, name: 'yo', userId: '123', description: 'desc');

    wl.description = testValue;

    expect(wl.description, testValue);
  });
  test('Should be able to update Post title', () {
    final wl = WishList(id: 1, name: 'yo', userId: '123', description: 'desc');

    wl.name = testValue;

    expect(wl.name, testValue);
  });
}
