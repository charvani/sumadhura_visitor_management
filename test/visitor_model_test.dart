import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumadhura_visitor_management/data/models/visitor.dart';
import 'package:sumadhura_visitor_management/data/repositories/visitor_repository.dart';
import 'package:sumadhura_visitor_management/presentation/controllers/visitor_controller.dart';

void main() {
  test('visitor JSON maps API fields and visit history', () {
    final visitor = Visitor.fromJson({
      'id': 'VIS001',
      'name': 'Rahul Sharma',
      'mobile': 9876543210,
      'email': 'rahul@example.com',
      'visitor_type': 'Customer',
      'project': 'Project A',
      'purpose': 'Site visit',
      'status': 'Checked In',
      'created_at': '2026-10-26T10:00:00+05:30',
      'check_in_time': '2026-10-26T10:30:00+05:30',
      'check_out_time': null,
      'history': [
        {'action': 'Checked In', 'timestamp': '2026-10-26T10:30:00+05:30'},
      ],
    });

    expect(visitor.id, 'VIS001');
    expect(visitor.mobile, '9876543210');
    expect(visitor.visitorType, 'Customer');
    expect(visitor.checkInTime, isNotNull);
    expect(visitor.checkOutTime, isNull);
    expect(visitor.history.single.action, 'Checked In');
    expect(Visitor.fromJson(visitor.toJson()).history, hasLength(1));
  });

  test(
    'local visit workflow rejects stale duplicate and completed updates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = VisitorController(VisitorRepository());
      await controller.loadVisitors();
      final now = DateTime.now();
      final draft = Visitor(
        id: '',
        name: 'Test Visitor',
        mobile: '9876543210',
        visitorType: 'Customer',
        project: 'Project C',
        purpose: 'Appointment',
        status: 'Registered',
        createdAt: now,
      );

      final registered = (await controller.saveVisitor(
        visitor: draft,
        isNew: true,
      ))!;
      final checkedIn = (await controller.updateVisitStatus(registered))!;
      expect(checkedIn.status, 'Checked In');
      expect(checkedIn.checkInTime, isNotNull);
      expect(checkedIn.history, hasLength(1));

      expect(await controller.updateVisitStatus(registered), isNull);
      expect(
        controller.visitors
            .firstWhere((visitor) => visitor.id == registered.id)
            .status,
        'Checked In',
      );

      final checkedOut = (await controller.updateVisitStatus(checkedIn))!;
      expect(checkedOut.status, 'Checked Out');
      expect(checkedOut.checkOutTime, isNotNull);
      expect(checkedOut.history, hasLength(2));
      expect(await controller.updateVisitStatus(checkedOut), isNull);
    },
  );
}
