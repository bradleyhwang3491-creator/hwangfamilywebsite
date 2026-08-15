import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../data/category_meta.dart';
import '../models/feed_card_data.dart';
import '../models/feed_item.dart';
import '../models/public_user.dart';
import '../providers/family_members_provider.dart';
import '../providers/home_feed_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/feed_card.dart';

const _avatarColors = [0xFF111827, 0xFF4B5563, 0xFF6B7280, 0xFF9CA3AF];
const _pageSize = 10;

class _Filter {
  final ActivityCategory? key; // null = all
  final String label;
  final String emoji;
  const _Filter(this.key, this.label, this.emoji);
}

const _filters = <_Filter>[
  _Filter(null, '전체', '✨'),
  _Filter(ActivityCategory.travel, '여행', '✈️'),
  _Filter(ActivityCategory.running, '러닝', '🏃'),
  _Filter(ActivityCategory.golf, '골프', '⛳'),
  _Filter(ActivityCategory.gym, '헬스', '💪'),
];

const _comingSoonCategories = {ActivityCategory.golf, ActivityCategory.gym};

/// Ported from src/pages/HomePage.tsx — feed is now real travel_records/
/// running_records data (via home_feed_provider.dart) instead of mock data.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ActivityCategory? _filter;
  int _page = 1;

  void _setFilter(ActivityCategory? key) {
    setState(() {
      _filter = key;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final familyAsync = ref.watch(familyMembersProvider);
    final feedAsync = ref.watch(homeFeedProvider);
    final members = familyAsync.valueOrNull ?? const <PublicUser>[];

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.grayBorder)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('황이서네 라이프로그', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text900)),
                        InkWell(
                          onTap: () => context.push('/my'),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.person_outline, size: 24, color: AppColors.text900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 60,
                      child: familyAsync.when(
                        data: (members) => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: members.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final m = members[i];
                            return Column(
                              children: [
                                m.avatarUrl != null
                                    ? ClipOval(
                                        child: Image.network(m.avatarUrl!, width: 44, height: 44, fit: BoxFit.cover),
                                      )
                                    : Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Color(_avatarColors[i % _avatarColors.length]),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.white, width: 2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          m.name.substring(0, 1),
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                const SizedBox(height: 4),
                                Text(m.name, style: const TextStyle(fontSize: 11, color: AppColors.text600)),
                              ],
                            );
                          },
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final f = _filters[i];
                          final active = _filter == f.key;
                          final meta = f.key != null ? categoryMeta[f.key]! : null;
                          return GestureDetector(
                            onTap: () => _setFilter(f.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? (meta != null ? Color(meta.bg) : AppColors.gray100) : AppColors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: active ? AppColors.text900 : AppColors.grayBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(f.emoji, style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Text(
                                    f.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: active ? AppColors.text900 : AppColors.text600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: feedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('불러오지 못했습니다: $e')),
              data: (allItems) => _buildBody(allItems, members),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentPath: '/home'),
    );
  }

  Widget _buildBody(List<FeedCardData> allItems, List<PublicUser> members) {
    final now = DateTime.now();
    final thisMonth = allItems.where((i) => i.sortDate.year == now.year && i.sortDate.month == now.month).toList();
    final thisMonthTravel = thisMonth.where((i) => i.category == ActivityCategory.travel).length;
    final thisMonthRunning = thisMonth.where((i) => i.category == ActivityCategory.running).length;

    final comingSoon = _filter != null && _comingSoonCategories.contains(_filter);
    final filteredFeed = _filter == null ? allItems : allItems.where((f) => f.category == _filter).toList();
    final totalPages = (filteredFeed.length / _pageSize).ceil().clamp(1, 1 << 30);
    final currentPage = _page.clamp(1, totalPages);
    final feed = filteredFeed.skip((currentPage - 1) * _pageSize).take(_pageSize).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF000000)],
            ),
          ),
          child: Row(
            children: [
              _SummaryStat(value: '${thisMonth.length}', label: '이번달 기록'),
              _divider(),
              _SummaryStat(value: '$thisMonthTravel', label: '여행'),
              _divider(),
              _SummaryStat(value: '$thisMonthRunning', label: '운동'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (comingSoon)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                Text(categoryMeta[_filter]!.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                const Text('준비중인 기능이에요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text900)),
                const SizedBox(height: 4),
                Text('다음 단계에서 ${categoryMeta[_filter]!.label} 기능을 만들 예정입니다.', style: const TextStyle(fontSize: 13, color: AppColors.text400)),
              ],
            ),
          )
        else if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                const Text('🗂️', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                const Text('아직 기록이 없어요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text900)),
                const SizedBox(height: 4),
                const Text('가족과의 첫 기록을 남겨보세요', style: TextStyle(fontSize: 13, color: AppColors.text400)),
              ],
            ),
          )
        else ...[
          for (final item in feed) ...[
            FeedCard(
              item: item,
              authorName: _authorName(members, item.authorId),
              authorAvatarColor: _authorAvatarColor(members, item.authorId),
            ),
            const SizedBox(height: 12),
          ],
          if (totalPages > 1) _Pagination(page: currentPage, totalPages: totalPages, onChange: (p) => setState(() => _page = p)),
        ],
      ],
    );
  }

  String _authorName(List<PublicUser> members, String authorId) {
    for (final m in members) {
      if (m.id == authorId) return m.name;
    }
    return '알 수 없음';
  }

  int _authorAvatarColor(List<PublicUser> members, String authorId) {
    final index = members.indexWhere((m) => m.id == authorId);
    if (index < 0) return _avatarColors[0];
    return _avatarColors[index % _avatarColors.length];
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25));
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
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
      padding: const EdgeInsets.only(top: 12),
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
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text600),
          ),
        ),
      ),
    );
  }
}
