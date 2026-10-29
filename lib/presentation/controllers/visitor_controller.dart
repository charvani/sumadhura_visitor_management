import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';
import 'package:sumadhura_visitor_management/data/repositories/visitor_repository.dart';

class VisitorController extends GetxController {
  VisitorController(this._repository);

  final VisitorRepository _repository;
  final visitors = <Visitor>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final isDarkMode = false.obs;
  final errorMessage = RxnString();
  final searchQuery = ''.obs;
  final projectFilter = 'All projects'.obs;
  final statusFilter = 'All statuses'.obs;
  final selectedTab = 0.obs;

  bool get localMode => _repository.isLocalMode;

  List<Visitor> get filteredVisitors {
    final query = searchQuery.value.trim().toLowerCase();
    return visitors.where((visitor) {
      final matchesQuery =
          query.isEmpty ||
          visitor.name.toLowerCase().contains(query) ||
          visitor.mobile.contains(query);
      final matchesProject =
          projectFilter.value == 'All projects' ||
          visitor.project == projectFilter.value;
      final matchesStatus =
          statusFilter.value == 'All statuses' ||
          visitor.status == statusFilter.value;
      return matchesQuery && matchesProject && matchesStatus;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get totalToday {
    final now = DateTime.now();
    return visitors.where((visitor) => _sameDay(visitor.createdAt, now)).length;
  }

  int get checkedInNow =>
      visitors.where((visitor) => visitor.status == 'Checked In').length;

  int get checkedOutToday => visitors
      .where(
        (visitor) =>
            visitor.checkOutTime != null &&
            _sameDay(visitor.checkOutTime!, DateTime.now()),
      )
      .length;

  @override
  void onInit() {
    super.onInit();
    loadVisitors();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    isDarkMode.value = await _repository.loadDarkMode();
  }

  Future<void> toggleTheme() async {
    final next = !isDarkMode.value;
    isDarkMode.value = next;
    Get.changeThemeMode(next ? ThemeMode.dark : ThemeMode.light);
    await _repository.saveDarkMode(next);
  }

  Future<void> loadVisitors({bool showLoader = true}) async {
    if (showLoader) isLoading.value = true;
    errorMessage.value = null;
    try {
      visitors.assignAll(await _repository.getVisitors());
    } catch (error) {
      try {
        final cached = await _repository.getCachedVisitors();
        if (cached.isNotEmpty) visitors.assignAll(cached);
        errorMessage.value = cached.isEmpty
            ? error.toString()
            : 'Could not refresh from API. Showing saved visitor data. $error';
      } catch (cacheError) {
        errorMessage.value = 'Could not load visitor data: $cacheError';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Visitor?> fetchVisitor(String id) async {
    try {
      final visitor = await _repository.getVisitor(id);
      _upsert(visitor);
      return visitor;
    } catch (error) {
      final cached = visitors.firstWhereOrNull((item) => item.id == id);
      if (cached != null) return cached;
      errorMessage.value = error.toString();
      return null;
    }
  }

  Future<Visitor?> saveVisitor({
    required Visitor visitor,
    required bool isNew,
  }) async {
    isSaving.value = true;
    try {
      final saved = await _repository.saveVisitor(visitor, isNew: isNew);
      _upsert(saved);
      errorMessage.value = null;
      return saved;
    } catch (error) {
      errorMessage.value = error.toString();
      return null;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteVisitor(String id) async {
    try {
      await _repository.deleteVisitor(id);
      visitors.removeWhere((visitor) => visitor.id == id);
      return true;
    } catch (error) {
      errorMessage.value = error.toString();
      return false;
    }
  }

  Future<Visitor?> updateVisitStatus(Visitor visitor) async {
    if (isSaving.value) {
      errorMessage.value = 'A visitor update is already in progress.';
      return null;
    }
    final current = visitors.firstWhereOrNull((item) => item.id == visitor.id);
    if (current != null && current.status != visitor.status) {
      errorMessage.value = 'The visitor status has changed. Refresh and retry.';
      return null;
    }
    final currentVisitor = current ?? visitor;
    final nextStatus = switch (currentVisitor.status) {
      'Registered' => 'Checked In',
      'Checked In' => 'Checked Out',
      _ => null,
    };
    if (nextStatus == null) {
      errorMessage.value = 'This visit has already been completed.';
      return null;
    }

    final now = DateTime.now();
    final nextHistory = [
      ...currentVisitor.history,
      VisitEvent(action: nextStatus, timestamp: now),
    ];
    final updated = currentVisitor.copyWith(
      status: nextStatus,
      checkInTime: nextStatus == 'Checked In'
          ? now
          : currentVisitor.checkInTime,
      checkOutTime: nextStatus == 'Checked Out'
          ? now
          : currentVisitor.checkOutTime,
      history: nextHistory,
    );
    return saveVisitor(visitor: updated, isNew: false);
  }

  void _upsert(Visitor visitor) {
    final index = visitors.indexWhere((item) => item.id == visitor.id);
    if (index == -1) {
      visitors.insert(0, visitor);
    } else {
      visitors[index] = visitor;
      visitors.refresh();
    }
  }

  bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
