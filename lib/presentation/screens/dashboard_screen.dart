import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_form_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Obx(
      () => RefreshIndicator(
        onRefresh: () => controller.loadVisitors(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text(
                'Visitor Management',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  tooltip: controller.isDarkMode.value
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  onPressed: controller.toggleTheme,
                  icon: Icon(
                    controller.isDarkMode.value
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    'Good ${_greeting()},',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is today at your front desk.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (controller.localMode) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.offline_bolt_outlined, size: 19),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo mode: changes are saved on this device.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Today’s overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (controller.errorMessage.value != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.errorMessage.value!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.loadVisitors(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _StatCard(
                    label: 'Total visitors today',
                    value: controller.totalToday,
                    icon: Icons.groups_2_outlined,
                    color: const Color(0xFF176B58),
                  ),
                  _StatCard(
                    label: 'Currently checked in',
                    value: controller.checkedInNow,
                    icon: Icons.meeting_room_outlined,
                    color: const Color(0xFF3D6FA5),
                  ),
                  _StatCard(
                    label: 'Checked out today',
                    value: controller.checkedOutToday,
                    icon: Icons.task_alt,
                    color: const Color(0xFF9A6414),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () => Get.to(() => const VisitorFormScreen()),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Register visitor'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.selectedTab.value = 1,
                      icon: const Icon(Icons.people_outline),
                      label: const Text('View visitor list'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.selectedTab.value = 2,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan visitor QR'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(child: Text(label)),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}
