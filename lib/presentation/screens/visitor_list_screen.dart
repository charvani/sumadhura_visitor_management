import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_form_screen.dart';
import 'package:sumadhura_visitor_management/presentation/widgets/visitor_widgets.dart';

class VisitorListScreen extends StatelessWidget {
  const VisitorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visitors',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh visitors',
            onPressed: () => controller.loadVisitors(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const VisitorFormScreen()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Register'),
      ),
      body: Obx(() {
        final filtered = controller.filteredVisitors;
        if (controller.isLoading.value && controller.visitors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.loadVisitors,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    TextField(
                      onChanged: (value) =>
                          controller.searchQuery.value = value,
                      decoration: const InputDecoration(
                        hintText: 'Search name or mobile number',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.projectFilter.value,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Project',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items:
                                const [
                                      'All projects',
                                      'Project A',
                                      'Project B',
                                      'Project C',
                                    ]
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.projectFilter.value = value;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: controller.statusFilter.value,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items:
                                const [
                                      'All statuses',
                                      'Registered',
                                      'Checked In',
                                      'Checked Out',
                                    ]
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(
                                          item,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.statusFilter.value = value;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${filtered.length} visitor${filtered.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (controller.isLoading.value)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    if (controller.errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(
                        message: controller.errorMessage.value!,
                        onRetry: () => controller.loadVisitors(),
                      ),
                    ],
                    if (filtered.isEmpty)
                      SizedBox(
                        height: 300,
                        child: EmptyState(
                          title: controller.visitors.isEmpty
                              ? 'No visitors yet'
                              : 'No matching visitors',
                          message: controller.visitors.isEmpty
                              ? 'Register your first visitor to get started.'
                              : 'Try changing your search or filters.',
                        ),
                      )
                    else
                      ...filtered.map(
                        (visitor) => VisitorCard(visitor: visitor),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message, maxLines: 3)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
