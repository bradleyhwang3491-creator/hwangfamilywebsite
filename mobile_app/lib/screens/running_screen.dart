import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/running_record.dart';
import '../providers/family_members_provider.dart';
import '../providers/running_records_provider.dart';
import '../providers/selected_running_user_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/bottom_nav.dart';

const _pageSize = 10;
const _avatarColors = [0xFF111827, 0xFF4B5563, 0xFF6B7280, 0xFF9CA3AF];
final _dateFmt = DateFormat('yyyy-MM-dd');

/// 러닝 탭 — 앱 안에서 GPS로 직접 기록한 러닝(running_records)을 월별로 보여준다.
/// Health Connect/삼성 헬스 연동은 없음(자체 트래킹으로 전환).
class RunningScreen extends ConsumerStatefulWidget {
  const RunningScreen({super.key});

  @override
  ConsumerState<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends ConsumerState<RunningScreen> {
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).valueOrNull;
    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 정보가 없습니다.', style: TextStyle(fontSize: 14, color: AppColors.text400))),
        bottomNavigationBar: BottomNav(currentPath: '/running'),
      );
    }

    final selectedMonth = ref.watch(selectedRunningMonthProvider);
    final selectedUserId = ref.watch(selectedRunningUserProvider) ?? session.id;
    final familyAsync = ref.watch(familyMembersProvider);
    final recordsAsync = ref.watch(runningRecordsProvider(selectedUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝 기록', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.grayBorder)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(runningRecordsProvider(selectedUserId)),
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
          data: (records) {
            final monthRecords = records
                .where((r) => r.runDate.year == selectedMonth.year && r.runDate.month == selectedMonth.month)
                .toList();
            final totalKm = monthRecords.fold<double>(0, (sum, r) => sum + r.distanceKm);
            final totalPages = (monthRecords.length / _pageSize).ceil().clamp(1, 1 << 30);
            final currentPage = _page.clamp(1, totalPages);
            final pageRecords = monthRecords.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _MonthPicker(
                  month: selectedMonth,
                  onChanged: (m) {
                    ref.read(selectedRunningMonthProvider.notifier).state = m;
                    setState(() => _page = 1);
                  },
                ),
                const SizedBox(height: 16),
                _StatsRow(count: monthRecords.length, km: totalKm),
                const SizedBox(height: 20),
                familyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (members) => SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final m = members[i];
                        final active = m.id == selectedUserId;
                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedRunningUserProvider.notifier).state = m.id == session.id ? null : m.id;
                            setState(() => _page = 1);
                          },
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: active ? AppColors.primary600 : Colors.transparent, width: 2),
                                ),
                                child: m.avatarUrl != null
                                    ? ClipOval(child: Image.network(m.avatarUrl!, width: 40, height: 40, fit: BoxFit.cover))
                                    : Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: Color(_avatarColors[i % _avatarColors.length]), shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text(m.name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                              ),
                              const SizedBox(height: 4),
                              Text(m.name, style: TextStyle(fontSize: 11, color: active ? AppColors.text900 : AppColors.text400, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (monthRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('이번 달 러닝 기록이 없어요', style: TextStyle(fontSize: 13, color: AppColors.text400))),
                  )
                else ...[
                  for (final record in pageRecords) ...[
                    _RecordCard(record: record, onTap: () => context.push('/running/record/${record.id}')),
                    const SizedBox(height: 12),
                  ],
                  if (totalPages > 1) _Pagination(page: currentPage, totalPages: totalPages, onChange: (p) => setState(() => _page = p)),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/running/new'),
        backgroundColor: AppColors.primary600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('러닝 기록', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      bottomNavigationBar: const BottomNav(currentPath: '/running'),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  const _MonthPicker({required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: () => onChanged(DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left, color: AppColors.text900)),
        Text('${month.year}년 ${month.month}월', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text900)),
        IconButton(onPressed: () => onChanged(DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right, color: AppColors.text900)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int count;
  final double km;
  const _StatsRow({required this.count, required this.km});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1F2937), Color(0xFF000000)]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('총 러닝 횟수', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                Text(km.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('이동 거리 (km)', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final RunningRecord record;
  final VoidCallback onTap;
  const _RecordCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayBorder),
          boxShadow: AppColors.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text900)),
            const SizedBox(height: 2),
            Text(_dateFmt.format(record.runDate), style: const TextStyle(fontSize: 12, color: AppColors.text400)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatChip(icon: '🏃', label: '${record.distanceKm.toStringAsFixed(2)} km'),
                if (record.avgSpeedKmh != null) _StatChip(icon: '⚡', label: '${record.avgSpeedKmh!.toStringAsFixed(1)} km/h'),
                if (record.maxHeartRate != null) _StatChip(icon: '❤️', label: '최대 ${record.maxHeartRate} bpm'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text900)),
        ],
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onChange;
  const _Pagination({required this.page, required this.totalPages, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        children: [
          _PageButton(label: '‹', enabled: page > 1, onTap: () => onChange((page - 1).clamp(1, totalPages))),
          for (var n = 1; n <= totalPages; n++) _PageButton(label: '$n', active: n == page, onTap: () => onChange(n)),
          _PageButton(label: '›', enabled: page < totalPages, onTap: () => onChange((page + 1).clamp(1, totalPages))),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  const _PageButton({required this.label, this.active = false, this.enabled = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary600 : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? AppColors.primary600 : AppColors.grayBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text600)),
        ),
      ),
    );
  }
}
