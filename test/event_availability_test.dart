import 'package:flutter_test/flutter_test.dart';
import 'package:gocollab/features/events/domain/entities/event.dart';

Event _event({
  required DateTime startAt,
  required DateTime endAt,
  EventStatus status = EventStatus.upcoming,
  DateTime? registrationDeadline,
  int registeredCount = 0,
  int? capacity,
}) {
  return Event(
    id: 'e1',
    title: 'Test',
    description: 'Desc',
    category: EventCategory.workshop,
    startAt: startAt,
    endAt: endAt,
    status: status,
    registrationDeadline: registrationDeadline,
    registeredCount: registeredCount,
    capacity: capacity,
  );
}

void main() {
  final now = DateTime.now();

  test('upcoming open events are available', () {
    final event = _event(
      startAt: now.add(const Duration(days: 7)),
      endAt: now.add(const Duration(days: 7, hours: 3)),
    );
    expect(event.isAvailable, isTrue);
    expect(event.registrationOpen, isTrue);
    expect(event.isPast, isFalse);
  });

  test('past events are not available', () {
    final event = _event(
      startAt: now.subtract(const Duration(days: 3)),
      endAt: now.subtract(const Duration(days: 2)),
      status: EventStatus.completed,
    );
    expect(event.isPast, isTrue);
    expect(event.isAvailable, isFalse);
  });

  test('closed registration is not available', () {
    final event = _event(
      startAt: now.add(const Duration(days: 7)),
      endAt: now.add(const Duration(days: 7, hours: 3)),
      registrationDeadline: now.subtract(const Duration(hours: 1)),
    );
    expect(event.registrationOpen, isFalse);
    expect(event.isAvailable, isFalse);
  });
}
