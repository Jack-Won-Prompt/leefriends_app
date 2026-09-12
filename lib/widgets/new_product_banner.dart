import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/store_ops.dart' show NewProductHighlight, won;
import '../theme/app_colors.dart';
import 'product_thumb.dart';

/// 대시보드 상단 "오늘의 신규 품목" 배너 — 대표 품목 이미지·이름·가격, 2건 이상이면 "외 N건".
/// 매장 홈(→ 발주 카탈로그)과 본사 홈(→ 품목 관리)이 함께 쓴다.
///
/// 하이라이트: 테두리·그림자가 천천히 밝아졌다 어두워지고(글로우), 주기마다 한 번 빛이 대각선으로
/// 스쳐 지나간다. 기기 "애니메이션 줄이기" 설정 시에는 움직임 없이 강조 색만 표시.
class NewProductBanner extends StatefulWidget {
  const NewProductBanner({super.key, required this.item, required this.onTap});
  final NewProductHighlight item;
  final VoidCallback onTap;

  @override
  State<NewProductBanner> createState() => _NewProductBannerState();
}

class _NewProductBannerState extends State<NewProductBanner>
    with SingleTickerProviderStateMixin {
  static const _radius = 18.0;

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final item = widget.item;
    final price = item.isMarketPrice
        ? '싯가'
        : '${won(item.storePrice)}${item.unit.isNotEmpty ? ' / ${item.unit}' : ''}';

    // 애니메이션과 무관한 본문 — 매 프레임 다시 만들지 않도록 AnimatedBuilder child 로 전달
    final content = Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ProductThumb(url: item.imageUrl, size: 64, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _NewBadge(),
                  const SizedBox(height: 6),
                  Row(children: [
                    Flexible(
                      child: Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    ),
                    if (item.others > 0)
                      Text(' 외 ${item.others}건',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.mango700)),
                  ]),
                  const SizedBox(height: 2),
                  Text(price,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ]),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _ctrl,
      child: content,
      builder: (context, child) {
        final t = reduceMotion ? 0.0 : _ctrl.value;
        // 0 → 1 → 0 로 부드럽게 오르내리는 글로우 세기 (움직임 줄이기 시 중간값 고정)
        final pulse = reduceMotion ? 0.5 : (1 - math.cos(t * 2 * math.pi)) / 2;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.10 + 0.22 * pulse),
                blurRadius: 10 + 12 * pulse,
                spreadRadius: 0.5 + 1.5 * pulse,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(children: [
              child!,
              if (!reduceMotion) Positioned.fill(child: IgnorePointer(child: _Shine(progress: t))),
              // 테두리는 빛보다 위에 그려 가려지지 않게
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                        color: Color.lerp(AppColors.mango300, AppColors.accent, pulse)!,
                        width: 1.2 + 0.6 * pulse,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// "오늘의 신규 품목" 라벨 — 그라데이션 칩 + 반짝이 아이콘.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.mango600, AppColors.accent]),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.auto_awesome, size: 12, color: Colors.white),
        SizedBox(width: 3),
        Text('오늘의 신규 품목',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }
}

/// 배너 위를 대각선으로 스쳐 지나가는 빛. 주기의 앞부분에만 지나가고 나머지는 쉰다.
class _Shine extends StatelessWidget {
  const _Shine({required this.progress});

  /// 전체 주기 진행률 0..1
  final double progress;

  /// 주기 중 빛이 지나가는 구간 비율 (나머지는 쉼 — 계속 번쩍이지 않게)
  static const _sweep = 0.4;

  @override
  Widget build(BuildContext context) {
    if (progress > _sweep) return const SizedBox.shrink();
    final p = Curves.easeInOut.transform(progress / _sweep);
    final x = -2.2 + 4.4 * p; // 왼쪽 밖 → 오른쪽 밖
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(x - 0.6, -1),
          end: Alignment(x + 0.6, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ),
      ),
    );
  }
}
