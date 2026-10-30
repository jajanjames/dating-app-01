import 'package:get/get.dart';
import '../../data/models/user_model.dart';
import '../../data/services/api_service.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = ApiService();

  UserModel? user;
  bool isLoading = false;

  Future<void> fetchProfile() async {
    // TODO: implement profile fetching using _apiService
    update();
  }
}
