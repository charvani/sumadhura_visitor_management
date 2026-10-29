import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_details_screen.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_form_screen.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color foreground, Color background) = switch (status) {
      'Checked In' => (const Color(0xFF16764E), const Color(0xFFE0F3E9)),
      'Checked Out' => (const Color(0xFF526477), const Color(0xFFE9EEF3)),
      _ => (const Color(0xFF9A6414), const Color(0xFFFFF1D9)),
    };
    return Chip(
      label: Text(status),
      visualDensity: VisualDensity.compact,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? foreground.withValues(alpha: .18)
          : background,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? foreground.withValues(alpha: .85)
            : foreground,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class VisitorCard extends StatelessWidget {
  const VisitorCard({super.key, required this.visitor});

  final Visitor visitor;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Get.to(() => VisitorDetailsScreen(visitorId: visitor.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  visitor.name.isEmpty ? '?' : visitor.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${visitor.mobile}  ·  ${visitor.project}'),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          visitor.visitorType,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        StatusChip(status: visitor.status),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') {
                    await Get.to(() => VisitorFormScreen(visitor: visitor));
                  } else {
                    final confirmed =
                        await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Delete visitor?'),
                            content: Text(
                              'This will permanently remove ${visitor.name} and their visit record.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (confirmed) {
                      final deleted = await controller.deleteVisitor(
                        visitor.id,
                      );
                      Get.snackbar(
                        deleted ? 'Visitor deleted' : 'Could not delete',
                        deleted
                            ? 'The visitor record was removed.'
                            : controller.errorMessage.value ?? 'Please retry.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.people_outline,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
