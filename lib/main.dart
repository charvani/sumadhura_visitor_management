import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/app/app.dart';
import 'package:sumadhura_visitor_management/data/repositories/visitor_repository.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(VisitorController(VisitorRepository()), permanent: true);
  runApp(const VisitorManagementApp());
}
