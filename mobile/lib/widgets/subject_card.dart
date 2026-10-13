import 'package:flutter/material.dart';
import '../models/subject.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.onShare,
  });

  Color get _color {
    try {
      final hex = subject.color.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1E2050);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = subject.topicCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon tile — matches _CategoryCard style
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                subject.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),

            const Spacer(),

            // Level pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subject.level,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _color,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              subject.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2050),
                height: 1.2,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Share button
            if (onShare != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 14),
                    label: const Text('Share',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),

            // Topic count row
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: hasContent
                        ? const Color(0xFF10B981)
                        : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    hasContent
                        ? '${subject.topicCount} topic${subject.topicCount == 1 ? '' : 's'}'
                        : 'Sync to download',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasContent
                          ? const Color(0xFF10B981)
                          : Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
