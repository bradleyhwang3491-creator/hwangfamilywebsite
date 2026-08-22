import 'package:flutter_test/flutter_test.dart';
import 'package:hwang_family_app/models/running_record.dart';

void main() {
  group('parseDurationInput', () {
    test('MM:SS', () => expect(RunningRecord.parseDurationInput('30:30'), 1830));
    test('H:MM:SS', () => expect(RunningRecord.parseDurationInput('1:05:00'), 3900));
    test('숫자만 적으면 분', () => expect(RunningRecord.parseDurationInput('45'), 2700));
    test('공백 허용', () => expect(RunningRecord.parseDurationInput(' 30:00 '), 1800));
    test('빈 값은 null', () => expect(RunningRecord.parseDurationInput('  '), isNull));
    test('문자는 null', () => expect(RunningRecord.parseDurationInput('abc'), isNull));
    test('자리수 초과는 null', () => expect(RunningRecord.parseDurationInput('1:2:3:4'), isNull));
  });

  group('parsePaceInput', () {
    test('분:초', () => expect(RunningRecord.parsePaceInput('5:30'), 330));
    test("분'초\" 표기", () => expect(RunningRecord.parsePaceInput("5'30\""), 330));
    test('분만', () => expect(RunningRecord.parsePaceInput('6'), 360));
    test('60초 이상은 null', () => expect(RunningRecord.parsePaceInput('5:60'), isNull));
    test('빈 값은 null', () => expect(RunningRecord.parsePaceInput(''), isNull));
    test('문자는 null', () => expect(RunningRecord.parsePaceInput('빠름'), isNull));
  });

  group('formatting', () {
    test('페이스 표시', () => expect(RunningRecord.formatPaceSeconds(352), "5'52\""));
    test('페이스 입력값', () => expect(RunningRecord.formatPaceInput(352), '5:52'));
    test('한 자리 초 패딩', () => expect(RunningRecord.formatPaceInput(305), '5:05'));
    test('1시간 미만', () => expect(RunningRecord.formatDuration(1830), '30:30'));
    test('1시간 이상', () => expect(RunningRecord.formatDuration(3900), '1:05:00'));
  });

  group('computePaceSeconds', () {
    test('5.2km / 30:30', () => expect(RunningRecord.computePaceSeconds(5200, 1830), 352));
    test('거리 0이면 null', () => expect(RunningRecord.computePaceSeconds(0, 1830), isNull));
    test('시간 0이면 null', () => expect(RunningRecord.computePaceSeconds(5200, 0), isNull));
  });

  group('입력 → 저장 → 표시 왕복', () {
    test('사용자가 친 값이 그대로 돌아온다', () {
      final seconds = RunningRecord.parsePaceInput('5:52')!;
      expect(RunningRecord.formatPaceInput(seconds), '5:52');
      expect(RunningRecord.formatPaceSeconds(seconds), "5'52\"");
    });

    test('저장된 페이스가 계산값보다 우선한다', () {
      final record = RunningRecord(
        id: 'x',
        userId: 'u',
        title: 't',
        runDate: DateTime(2026, 8, 22),
        startTime: DateTime(2026, 8, 22, 7),
        endTime: DateTime(2026, 8, 22, 7, 30),
        durationSeconds: 1830,
        distanceMeters: 5200,
        avgPaceSeconds: 300, // 계산하면 352초지만 사용자가 직접 고친 값
      );
      expect(record.paceLabel, "5'00\"");
    });

    test('페이스가 없는 옛 기록은 계산값으로 채운다', () {
      final record = RunningRecord(
        id: 'x',
        userId: 'u',
        title: 't',
        runDate: DateTime(2026, 8, 22),
        startTime: DateTime(2026, 8, 22, 7),
        endTime: DateTime(2026, 8, 22, 7, 30),
        durationSeconds: 1830,
        distanceMeters: 5200,
      );
      expect(record.paceLabel, "5'52\"");
    });
  });
}
