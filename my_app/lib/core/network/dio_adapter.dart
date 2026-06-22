import 'package:dio/dio.dart';

import 'dio_adapter_stub.dart'
    if (dart.library.io) 'dio_adapter_io.dart' as impl;

void setupDioAdapter(Dio dio) => impl.configureDioAdapter(dio);
