import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/dashboard_screen.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_list_screen.dart';
import 'package:sumadhura_visitor_management/presentation/screens/qr_scanner_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Obx(
      () => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: controller.selectedTab.value,
            children: [
              const DashboardScreen(),
              const VisitorListScreen(),
              if (controller.selectedTab.value == 2)
                const QrScannerScreen()
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.selectedTab.value,
          onDestinationSelected: (index) {
            controller.selectedTab.value = index;
            if (index == 1) controller.loadVisitors(showLoader: false);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Visitors',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
          ],
        ),
      ),
    );
  }
}
