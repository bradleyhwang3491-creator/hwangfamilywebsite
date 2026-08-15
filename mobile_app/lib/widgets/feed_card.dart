import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../data/category_meta.dart';
import '../models/feed_card_data.dart';

/// Ported from src/components/FeedCard.tsx — now backed by real DB data
/// (travel_records/running_records) instead of mock feed items. No more
/// like button; shows the author instead, and the outer border is colored
/// per category.
class FeedCard extends StatelessWidget {
  final FeedCardData item;
  final String authorName;
  final int authorAvatarColor;

  const FeedCard({super.key, required this.item, required this.authorName, required this.authorAvatarColor});

  @override
  Widget build(BuildContext context) {
    final meta = categoryMeta[item.category]!;
    final borderColor = Color(categoryBorderColor[item.category]!);

    return InkWell(
      onTap: () => context.push(item.detailPath),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: AppColors.shadowCard,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.thumbnailUrl != null) Image.network(item.thumbnailUrl!, width: double.infinity, height: 176, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Color(meta.bg), borderRadius: BorderRadius.circular(999)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(meta.emoji, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(meta.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(meta.color))),
                          ],
                        ),
                      ),
                      Text(item.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.text400)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text900),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.stats
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(s.icon, style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 3),
                                  Text(s.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text900)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.grayBorder))),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(color: Color(authorAvatarColor), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            authorName.isNotEmpty ? authorName.substring(0, 1) : '?',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(authorName, style: const TextStyle(fontSize: 11, color: AppColors.text600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
