import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/travel_record_photo.dart';

/// Ported from the PhotoLightbox component inside TravelRecordDetailPage.tsx.
/// Download opens the image externally (browser tab on web, default
/// image handler on mobile) instead of a raw blob download, since Flutter
/// has no cross-platform "save file" primitive without extra native setup.
class PhotoLightbox extends StatefulWidget {
  final List<TravelRecordPhoto> photos;
  final int index;
  final VoidCallback onClose;
  final ValueChanged<int> onChangeIndex;

  const PhotoLightbox({
    super.key,
    required this.photos,
    required this.index,
    required this.onClose,
    required this.onChangeIndex,
  });

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> {
  bool _downloading = false;

  Future<void> _handleDownload() async {
    setState(() => _downloading = true);
    try {
      final uri = Uri.parse(widget.photos[widget.index].url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = widget.index > 0;
    final hasNext = widget.index < widget.photos.length - 1;
    final photo = widget.photos[widget.index];

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.95),
        child: SafeArea(
          child: Stack(
            children: [
              GestureDetector(onTap: widget.onClose, child: Container(color: Colors.transparent)),
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.download,
                      onTap: _downloading ? null : _handleDownload,
                    ),
                    const SizedBox(width: 8),
                    _CircleButton(icon: Icons.close, onTap: widget.onClose),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Image.network(photo.url, fit: BoxFit.contain),
                ),
              ),
              if (hasPrev)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CircleButton(icon: Icons.chevron_left, onTap: () => widget.onChangeIndex(widget.index - 1)),
                  ),
                ),
              if (hasNext)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _CircleButton(icon: Icons.chevron_right, onTap: () => widget.onChangeIndex(widget.index + 1)),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Text(
                  '${widget.index + 1} / ${widget.photos.length}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
