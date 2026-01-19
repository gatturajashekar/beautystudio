
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services_api.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<String> photos = [];
  List<Map<String, dynamic>> videos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      await ServicesApi.loadGallery();
      photos = List<String>.from(ServicesApi.getGalleryPhotos());
      videos = List<Map<String, dynamic>>.from(
        ServicesApi.getGalleryVideos(),
      );
    } catch (_) {
      photos = [];
      videos = [];
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        title: const Text("Gallery"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (photos.isNotEmpty) ...[
                  _sectionTitle("Photos"),
                  _photoGrid(),
                  const SizedBox(height: 20),
                ],
                if (videos.isNotEmpty) ...[
                  _sectionTitle("Videos"),
                  _videoGrid(),
                ],
              ],
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= PHOTOS =================

  Widget _photoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (_, index) {
        final url = photos[index];

        return GestureDetector(
          onTap: () => _openImage(url),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  // ================= VIDEOS (THUMBNAIL SAFE) =================

  Widget _videoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (_, index) {
        final video = videos[index];
        final videoUrl = video["video"] as String?;
        final thumbUrl = video["thumb"] as String?;

        return GestureDetector(
          onTap: videoUrl == null ? null : () => _openVideo(videoUrl),
          child: Stack(
            children: [
              Positioned.fill(
                child: thumbUrl == null
                    ? Container(
                        color: Colors.black12,
                        child: const Icon(
                          Icons.videocam,
                          size: 40,
                          color: Colors.black54,
                        ),
                      )
                    : Image.network(
                        thumbUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= NAV =================

  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(url: url),
      ),
    );
  }

  void _openVideo(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideo(url: url),
      ),
    );
  }
}

// =====================================================
// FULL SCREEN IMAGE — SAFE
// =====================================================

class FullScreenImage extends StatelessWidget {
  final String url;
  const FullScreenImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }
}

// =====================================================
// FULL SCREEN VIDEO — BULLETPROOF
// =====================================================

class FullScreenVideo extends StatefulWidget {
  final String url;
  const FullScreenVideo({super.key, required this.url});

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  VideoPlayerController? controller;
  bool showControls = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (!mounted) return;

      setState(() => controller = c);
      c.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Icon(Icons.error, color: Colors.white, size: 40),
        ),
      );
    }

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final c = controller!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => setState(() => showControls = !showControls),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio:
                    c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            if (showControls) ...[
              Center(
                child: IconButton(
                  iconSize: 64,
                  color: Colors.white,
                  icon: Icon(
                    c.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  onPressed: () {
                    setState(() {
                      c.value.isPlaying ? c.pause() : c.play();
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      c,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.orange,
                        bufferedColor: Colors.white54,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(c.value.position),
                            style: const TextStyle(color: Colors.white)),
                        Text(_fmt(c.value.duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
