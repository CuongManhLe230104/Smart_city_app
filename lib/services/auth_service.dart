import '../models/user_model.dart';

class AuthService {
  // Giả lập đăng nhập: nếu username và password đúng thì trả về UserModel
  static Future<UserModel?> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Giả lập chờ server

    if (username == 'admin' && password == '123456') {
      return UserModel(username: username, email: 'admin@example.com');
    } else {
      return null;
    }
  }
}
