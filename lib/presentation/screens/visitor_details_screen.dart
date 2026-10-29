import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_form_screen.dart';
import 'package:sumadhura_visitor_management/presentation/widgets/visitor_widgets.dart';

class VisitorDetailsScreen extends StatefulWidget {
  const VisitorDetailsScreen({super.key, required this.visitorId});

  final String visitorId;

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<VisitorController>();
    if (!controller.visitors.any((visitor) => visitor.id == widget.visitorId)) {
      controller.fetchVisitor(widget.visitorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor details'),
        actions: [
          Obx(() {
            final visitor = _visitor(controller);
            return IconButton(
              tooltip: 'Edit visitor',
              onPressed: visitor == null
                  ? null
                  : () => Get.to(() => VisitorFormScreen(visitor: visitor)),
              icon: const Icon(Icons.edit_outlined),
            );
          }),
        ],
      ),
      body: Obx(() {
        final visitor = _visitor(controller);
        if (visitor == null) {
          if (controller.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage.value!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          controller.fetchVisitor(widget.visitorId),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 27,
                          child: Text(
                            visitor.name.isEmpty
                                ? '?'
                                : visitor.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visitor.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text('Visitor ID: ${visitor.id}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    StatusChip(status: visitor.status),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile',
                      value: visitor.mobile,
                    ),
                    if (visitor.email?.isNotEmpty == true)
                      _InfoRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: visitor.email!,
                      ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Visitor type',
                      value: visitor.visitorType,
                    ),
                    _InfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'Project',
                      value: visitor.project,
                    ),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Purpose',
                      value: visitor.purpose,
                    ),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Registered',
                      value: _format(visitor.createdAt),
                    ),
                    if (visitor.checkInTime != null)
                      _InfoRow(
                        icon: Icons.login_outlined,
                        label: 'Checked in',
                        value: _format(visitor.checkInTime!),
                      ),
                    if (visitor.checkOutTime != null)
                      _InfoRow(
                        icon: Icons.logout_outlined,
                        label: 'Checked out',
                        value: _format(visitor.checkOutTime!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Visitor pass',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Scan this code to retrieve the visitor record.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: QrImageView(
                        data: visitor.id,
                        version: QrVersions.auto,
                        size: 190,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      visitor.id,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit history',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (visitor.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text('No check-in or check-out activity yet.'),
                      )
                    else
                      ...visitor.history.reversed.map(
                        (event) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            event.action == 'Checked In'
                                ? Icons.login
                                : Icons.logout,
                          ),
                          title: Text(event.action),
                          subtitle: Text(_format(event.timestamp)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Obx(() {
              final current = _visitor(controller);
              if (current == null || current.status == 'Checked Out') {
                return const SizedBox.shrink();
              }
              final isCheckIn = current.status == 'Registered';
              return SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          final updated = await controller.updateVisitStatus(
                            current,
                          );
                          if (updated != null) {
                            Get.snackbar(
                              isCheckIn
                                  ? 'Visitor checked in'
                                  : 'Visitor checked out',
                              '${updated.name} is now ${updated.status.toLowerCase()}.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              'Could not update visit',
                              controller.errorMessage.value ??
                                  'Please try again.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                  icon: Icon(isCheckIn ? Icons.login : Icons.logout),
                  label: Text(
                    isCheckIn ? 'Check in visitor' : 'Check out visitor',
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  Visitor? _visitor(VisitorController controller) {
    for (final visitor in controller.visitors) {
      if (visitor.id == widget.visitorId) return visitor;
    }
    return null;
  }

  String _format(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}  '
        '$hour:$minute $period';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 11),
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
