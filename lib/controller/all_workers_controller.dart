import 'package:emartprovider/model/worker_model.dart';
import 'package:emartprovider/services/firebase_helper.dart';
import 'package:get/get.dart';

class AllWorkersController extends GetxController {
  RxList<WorkerModel> workerModel = <WorkerModel>[].obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await FireStoreUtils.getAllWorkers().then((value) {
      workerModel.value = value;
    });
  }
}
