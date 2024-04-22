

import 'package:connectivity_plus/connectivity_plus.dart';

class InternetConnectivity {

  Future<bool> checkInternetConnection() async{
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    else{
      return true;
    }
  }

}
