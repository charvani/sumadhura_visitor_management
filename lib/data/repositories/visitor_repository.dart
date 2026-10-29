import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';

class VisitorRepository {
  VisitorRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? const String.fromEnvironment('API_BASE_URL'))
          .trim()
          .replaceFirst(RegExp(r'/$'), '');

  static const _visitorsKey = 'visitors_cache_v1';
  static const _themeKey = 'dark_mode_v1';
  final http.Client _client;
  final String _baseUrl;

  bool get isLocalMode => _baseUrl.isEmpty;

  Future<List<Visitor>> getCachedVisitors() => _readCachedVisitors();

  Future<List<Visitor>> getVisitors() async {
    if (isLocalMode) return _readLocalVisitors();
    final response = await _request('GET', '/visitors');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const VisitorApiException(
        'The API returned an invalid visitor list.',
      );
    }
    final visitors = decoded
        .whereType<Map>()
        .map((item) => Visitor.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    await _writeLocalVisitors(visitors);
    return visitors;
  }

  Future<Visitor> getVisitor(String id) async {
    if (isLocalMode) {
      final result = (await _readLocalVisitors()).where((v) => v.id == id);
      if (result.isEmpty) throw const VisitorNotFoundException();
      return result.first;
    }
    final response = await _request(
      'GET',
      '/visitors/${Uri.encodeComponent(id)}',
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const VisitorApiException('The API returned an invalid visitor.');
    }
    final visitor = Visitor.fromJson(Map<String, dynamic>.from(decoded));
    final visitors = await _readCachedVisitors();
    final index = visitors.indexWhere((item) => item.id == id);
    if (index == -1) {
      visitors.add(visitor);
    } else {
      visitors[index] = visitor;
    }
    await _writeLocalVisitors(visitors);
    return visitor;
  }

  Future<Visitor> saveVisitor(Visitor visitor, {required bool isNew}) async {
    if (isLocalMode) {
      final visitors = await _readLocalVisitors();
      if (isNew) {
        final created = Visitor(
          id: 'VIS-${DateTime.now().microsecondsSinceEpoch}',
          name: visitor.name,
          mobile: visitor.mobile,
          email: visitor.email,
          visitorType: visitor.visitorType,
          project: visitor.project,
          purpose: visitor.purpose,
          status: 'Registered',
          createdAt: DateTime.now(),
        );
        visitors.insert(0, created);
        await _writeLocalVisitors(visitors);
        return created;
      }
      final index = visitors.indexWhere((item) => item.id == visitor.id);
      if (index == -1) throw const VisitorNotFoundException();
      visitors[index] = visitor;
      await _writeLocalVisitors(visitors);
      return visitor;
    }

    final path = isNew
        ? '/visitors'
        : '/visitors/${Uri.encodeComponent(visitor.id)}';
    final response = await _request(
      isNew ? 'POST' : 'PUT',
      path,
      body: visitor.toJson()..remove('id'),
    );
    final decoded = response.body.trim().isEmpty
        ? null
        : jsonDecode(response.body);
    if (decoded != null && decoded is! Map) {
      throw const VisitorApiException('The API returned an invalid visitor.');
    }
    final responseJson = decoded == null
        ? null
        : Map<String, dynamic>.from(decoded as Map);
    responseJson?.putIfAbsent('id', () => visitor.id);
    final saved = responseJson == null
        ? visitor
        : Visitor.fromJson(responseJson);
    if (saved.id.isEmpty) {
      throw const VisitorApiException(
        'The API did not return a visitor ID after registration.',
      );
    }
    final cached = await _readCachedVisitors();
    final index = cached.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      cached.insert(0, saved);
    } else {
      cached[index] = saved;
    }
    await _writeLocalVisitors(cached);
    return saved;
  }

  Future<void> deleteVisitor(String id) async {
    if (!isLocalMode) {
      await _request('DELETE', '/visitors/${Uri.encodeComponent(id)}');
    }
    final visitors = await _readCachedVisitors();
    visitors.removeWhere((visitor) => visitor.id == id);
    await _writeLocalVisitors(visitors);
  }

  Future<bool> loadDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_themeKey) ?? false;
  }

  Future<void> saveDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_themeKey, value);
  }

  Future<List<Visitor>> _readLocalVisitors() async {
    final cached = await _readCachedVisitors();
    if (cached.isNotEmpty) return cached;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_visitorsKey)) return cached;
    final samples = _sampleVisitors();
    await _writeLocalVisitors(samples);
    return samples;
  }

  Future<List<Visitor>> _readCachedVisitors() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_visitorsKey);
    if (value == null) return [];
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw const VisitorApiException('Saved visitor data is corrupted.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => Visitor.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _writeLocalVisitors(List<Visitor> visitors) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _visitorsKey,
      jsonEncode(visitors.map((visitor) => visitor.toJson()).toList()),
    );
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final request = http.Request(method, uri)
        ..headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final success = response.statusCode >= 200 && response.statusCode < 300;
      if (!success) {
        throw VisitorApiException(
          'Request failed (${response.statusCode}). ${response.body}',
        );
      }
      return response;
    } on VisitorApiException {
      rethrow;
    } catch (error) {
      throw VisitorApiException('Could not reach the visitor API: $error');
    }
  }

  List<Visitor> _sampleVisitors() {
    final now = DateTime.now();
    final todayAt = DateTime(now.year, now.month, now.day, 9);
    return [
      Visitor(
        id: 'VIS001',
        name: 'Rahul Sharma',
        mobile: '9876543210',
        email: 'rahul@example.com',
        visitorType: 'Customer',
        project: 'Project A',
        purpose: 'Site Visit',
        status: 'Checked In',
        createdAt: todayAt,
        checkInTime: todayAt.add(const Duration(minutes: 30)),
        history: [
          VisitEvent(
            action: 'Checked In',
            timestamp: todayAt.add(const Duration(minutes: 30)),
          ),
        ],
      ),
      Visitor(
        id: 'VIS002',
        name: 'Ananya Rao',
        mobile: '9123456780',
        visitorType: 'Vendor',
        project: 'Project B',
        purpose: 'Material delivery',
        status: 'Registered',
        createdAt: todayAt.add(const Duration(hours: 1)),
      ),
      Visitor(
        id: 'VIS003',
        name: 'Kiran Kumar',
        mobile: '9988776655',
        visitorType: 'Other',
        project: 'Project A',
        purpose: 'Maintenance',
        status: 'Checked Out',
        createdAt: todayAt.subtract(const Duration(days: 1)),
        checkInTime: todayAt
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 1)),
        checkOutTime: todayAt
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 2)),
        history: [
          VisitEvent(
            action: 'Checked In',
            timestamp: todayAt
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 1)),
          ),
          VisitEvent(
            action: 'Checked Out',
            timestamp: todayAt
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 2)),
          ),
        ],
      ),
    ];
  }
}

class VisitorApiException implements Exception {
  const VisitorApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VisitorNotFoundException extends VisitorApiException {
  const VisitorNotFoundException() : super('Visitor not found.');
}
