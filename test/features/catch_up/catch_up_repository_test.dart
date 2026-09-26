import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/features/catch_up/data/catch_up_repository.dart';

void main() {
  test('filters unfinished and expired programmes and sorts newest first', () {
    final now = DateTime.utc(2026, 9, 26, 20);
    EpgProgram program(String id, DateTime start, DateTime end) => EpgProgram(
      id: id.hashCode,
      epgId: id,
      title: id,
      start: start,
      end: end,
    );

    final result = filterArchivedPrograms(
      [
        program(
          'older-valid',
          now.subtract(const Duration(hours: 5)),
          now.subtract(const Duration(hours: 4)),
        ),
        program(
          'newer-valid',
          now.subtract(const Duration(hours: 2)),
          now.subtract(const Duration(hours: 1)),
        ),
        program(
          'live',
          now.subtract(const Duration(minutes: 30)),
          now.add(const Duration(minutes: 30)),
        ),
        program(
          'expired',
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 2, hours: -1)),
        ),
      ],
      now: now,
      archiveDays: 1,
    );

    expect(result.map((program) => program.epgId), [
      'newer-valid',
      'older-valid',
    ]);
    expect(() => result.add(result.first), throwsUnsupportedError);
  });

  test('clamps archive windows to one through thirty days', () {
    final now = DateTime.utc(2026, 9, 26, 20);
    final twoDaysOld = EpgProgram(
      id: 1,
      epgId: 'two-days-old',
      title: 'Old programme',
      start: now.subtract(const Duration(days: 2)),
      end: now.subtract(const Duration(days: 2, hours: -1)),
    );

    expect(
      filterArchivedPrograms([twoDaysOld], now: now, archiveDays: 0),
      isEmpty,
    );
    expect(filterArchivedPrograms([twoDaysOld], now: now, archiveDays: 60), [
      twoDaysOld,
    ]);
  });
}
