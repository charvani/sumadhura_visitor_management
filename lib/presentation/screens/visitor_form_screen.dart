import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';
import 'package:sumadhura_visitor_management/presentation/screens/visitor_details_screen.dart';

class VisitorFormScreen extends StatefulWidget {
  const VisitorFormScreen({super.key, this.visitor});

  final Visitor? visitor;

  @override
  State<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends State<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _purpose;
  late String _visitorType;
  late String _project;
  bool get _isNew => widget.visitor == null;

  @override
  void initState() {
    super.initState();
    final visitor = widget.visitor;
    _name = TextEditingController(text: visitor?.name ?? '');
    _mobile = TextEditingController(text: visitor?.mobile ?? '');
    _email = TextEditingController(text: visitor?.email ?? '');
    _purpose = TextEditingController(text: visitor?.purpose ?? '');
    _visitorType = visitor?.visitorType ?? 'Customer';
    _project = visitor?.project ?? 'Project A';
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VisitorController>();
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Register visitor' : 'Edit visitor')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                _isNew ? 'Visitor information' : 'Update visitor information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isNew
                    ? 'Complete the details to create a visitor pass.'
                    : 'Changes will be saved to the visitor record.',
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Visitor name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the visitor name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(
                  labelText: 'Mobile number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a mobile number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Enter exactly 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isNotEmpty &&
                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _visitorType,
                decoration: const InputDecoration(
                  labelText: 'Visitor type',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const ['Customer', 'Vendor', 'Other']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _visitorType = value);
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _project,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                items: const ['Project A', 'Project B', 'Project C']
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _project = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _purpose,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Purpose of visit *',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the purpose of visit'
                    : null,
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: controller.isSaving.value ? null : _submit,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isNew ? 'Register visitor' : 'Save changes'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final creating = _isNew;
    final previous = widget.visitor;
    final draft = Visitor(
      id: previous?.id ?? '',
      name: _name.text.trim(),
      mobile: _mobile.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      visitorType: _visitorType,
      project: _project,
      purpose: _purpose.text.trim(),
      status: previous?.status ?? 'Registered',
      createdAt: previous?.createdAt ?? DateTime.now(),
      checkInTime: previous?.checkInTime,
      checkOutTime: previous?.checkOutTime,
      history: previous?.history ?? const [],
    );
    final controller = Get.find<VisitorController>();
    final saved = await controller.saveVisitor(visitor: draft, isNew: _isNew);
    if (!mounted) return;
    if (saved == null) {
      Get.snackbar(
        'Could not save visitor',
        controller.errorMessage.value ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.back(result: saved);
    Get.snackbar(
      creating ? 'Visitor registered' : 'Visitor updated',
      creating ? 'Visitor ID: ${saved.id}' : 'Changes saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
    if (creating) {
      Get.to(() => VisitorDetailsScreen(visitorId: saved.id));
    }
  }
}
