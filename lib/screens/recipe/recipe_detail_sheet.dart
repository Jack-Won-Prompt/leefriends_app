import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../models/recipe.dart';
import '../../theme/app_colors.dart';

/// 레시피 상세 — 바닥 시트 팝업(화면 이동 없음). 매장·본사 공용.
/// content 는 표준 HTML 이며 [HtmlWidget] 으로 렌더한다.
Future<void> showRecipeDetailSheet(BuildContext context, RecipeItem r) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(100)),
            ),
          ),
          if ((r.imageUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    r.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.cream,
                      child: const Icon(Icons.menu_book_outlined,
                          size: 40, color: AppColors.inkSoft),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((r.productName ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.mango100,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(r.productName!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mango800)),
                  ),
                if ((r.productName ?? '').isNotEmpty) const SizedBox(height: 8),
                Text(r.title,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800, height: 1.35)),
                if ((r.author ?? '').isNotEmpty || (r.createdAt ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                      [
                        if ((r.author ?? '').isNotEmpty) r.author! else '본사',
                        if ((r.createdAt ?? '').isNotEmpty) r.createdAt!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 14),
                // 업로드 영상 — 앱 내 재생
                if ((r.videoUrl ?? '').isNotEmpty) ...[
                  const _VideoLabel('🎬 레시피 영상'),
                  const SizedBox(height: 8),
                  _RecipeVideoPlayer(url: r.videoUrl!),
                  const SizedBox(height: 16),
                ],
                // 외부 영상 링크(유튜브 등) — 외부 앱/브라우저로 열기
                if ((r.videoLink ?? '').isNotEmpty) ...[
                  _ExternalVideoButton(link: r.videoLink!),
                  const SizedBox(height: 16),
                ],
                if ((r.content ?? '').trim().isEmpty)
                  const Text('내용이 없습니다.',
                      style: TextStyle(fontSize: 15, color: AppColors.inkSoft))
                else
                  HtmlWidget(
                    r.content!,
                    textStyle: const TextStyle(
                        fontSize: 15, color: AppColors.ink, height: 1.6),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 레시피 카드(목록용) — 이미지 썸네일 + 물품 배지 + 제목. 탭하면 상세 시트.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap, this.trailing});
  final RecipeItem recipe;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (r.imageUrl ?? '').isNotEmpty
                            ? Image.network(
                                r.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _thumbPlaceholder(),
                              )
                            : _thumbPlaceholder(),
                        if (r.hasVideo)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(100)),
                              child: const Text('▶ 영상',
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if ((r.productName ?? '').isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.mango100,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(r.productName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mango800)),
                          ),
                          const SizedBox(height: 5),
                        ],
                        Text(r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
                        if ((r.createdAt ?? '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                              [
                                if ((r.author ?? '').isNotEmpty) r.author! else '본사',
                                r.createdAt!,
                              ].join(' · '),
                              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ],
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
        color: AppColors.cream,
        child: const Icon(Icons.menu_book_outlined, color: AppColors.inkSoft, size: 30),
      );
}

class _VideoLabel extends StatelessWidget {
  const _VideoLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
      );
}

/// 업로드된 영상을 앱 안에서 재생. 탭하면 재생/일시정지, 하단에 진행바.
class _RecipeVideoPlayer extends StatefulWidget {
  const _RecipeVideoPlayer({required this.url});
  final String url;

  @override
  State<_RecipeVideoPlayer> createState() => _RecipeVideoPlayerState();
}

class _RecipeVideoPlayerState extends State<_RecipeVideoPlayer> {
  VideoPlayerController? _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
    c.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _box(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
            aspectRatio: 16 / 9, child: Container(color: Colors.black, child: child)),
      );

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_error) {
      return _box(const Center(
          child: Text('영상을 불러오지 못했습니다',
              style: TextStyle(color: Colors.white70, fontSize: 13))));
    }
    if (c == null || !c.value.isInitialized) {
      return _box(const Center(child: CircularProgressIndicator(color: Colors.white)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio <= 0 ? 16 / 9 : c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
              child: AnimatedOpacity(
                opacity: c.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.play_circle_fill, size: 56, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 외부 영상 링크(유튜브 등)를 외부 앱/브라우저로 연다.
class _ExternalVideoButton extends StatelessWidget {
  const _ExternalVideoButton({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(link.trim());
          final ok = uri != null &&
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('영상을 열 수 없습니다')));
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.mango300),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.play_circle_outline, size: 20),
        label: const Text('영상 보기 (외부 링크)',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
