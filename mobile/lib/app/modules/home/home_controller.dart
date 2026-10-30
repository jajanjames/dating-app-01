import 'package:get/get.dart';
import '../../data/services/api_service.dart';

class HomeController extends GetxController {
  final ApiService _apiService = ApiService();

  int selectedIndex = 0;

  void changeTab(int index) {
    selectedIndex = index;
    update();
  }

  Future<void> fetchHomeData() async {
    // TODO: implement home data fetching using _apiService
  }
}
