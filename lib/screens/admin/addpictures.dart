import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class AdminUploadBanners extends StatefulWidget {
  const AdminUploadBanners({super.key});

  @override
  State<AdminUploadBanners> createState() => _AdminUploadBannersState();
}

class _AdminUploadBannersState extends State<AdminUploadBanners>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool loadingHome = true;
  bool loadingGalleryPhotos = true;
  bool loadingGalleryVideos = true;

  List<String> homepageImages = [];
  List<String> galleryPhotos = [];
  List<Map<String, dynamic>> galleryVideos = [];

  // ✅ SAME SOURCE AS HOME PAGE (ONLY CHANGE)
  final String homepageApiUrl =
      "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/images/homepage";

  // ✅ ALREADY CORRECT
  final String galleryApiUrl =
      "https://v8dry8c37e.execute-api.us-east-1.amazonaws.com/prod/images/gallery";

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    fetchHomepage();
    fetchGalleryData();
  }

  // ================= HOMEPAGE (FIXED ONLY HERE) =================

  Future<void> fetchHomepage() async {
    try {
      final res = await http.get(Uri.parse(homepageApiUrl));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List list = decoded["images"] ?? [];
        homepageImages = list.map((e) => e.toString()).toList();
      }
    } catch (_) {
      homepageImages = [];
    } finally {
      if (mounted) {
        setState(() => loadingHome = false);
      }
    }
  }

  // ================= GALLERY (UNCHANGED) =================

  Future<void> fetchGalleryData() async {
    try {
      final res = await http.get(Uri.parse(galleryApiUrl));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        galleryPhotos = List<String>.from(body["photos"] ?? []);
        galleryVideos =
            List<Map<String, dynamic>>.from(body["videos"] ?? []);
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingGalleryPhotos = false;
          loadingGalleryVideos = false;
        });
      }
    }
  }

  // ================= UI HELPERS (UNCHANGED) =================

  Widget buildImageGrid(List<String> images, bool loading) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (images.isEmpty) return const Center(child: Text("No images found"));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(images[i], fit: BoxFit.cover),
      ),
    );
  }

  Widget buildGalleryPhotos(bool loading) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (galleryPhotos.isEmpty) return const Center(child: Text("No photos"));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: galleryPhotos.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(galleryPhotos[i], fit: BoxFit.cover),
      ),
    );
  }

  Widget buildGalleryVideos(bool loading) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (galleryVideos.isEmpty) return const Center(child: Text("No videos"));

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: galleryVideos.length,
      itemBuilder: (_, i) {
        final video = galleryVideos[i];
        final videoUrl = video["video"];
        final thumbUrl = video["thumb"];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerPage(url: videoUrl),
              ),
            );
          },
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              const Positioned.fill(
                child: Center(
                  child: Icon(Icons.play_circle_fill,
                      size: 50, color: Colors.white),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // ================= BUILD (UNCHANGED) =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Media Viewer"),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: "Homepage"),
            Tab(text: "Photos"),
            Tab(text: "Videos"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          buildImageGrid(homepageImages, loadingHome),
          buildGalleryPhotos(loadingGalleryPhotos),
          buildGalleryVideos(loadingGalleryVideos),
        ],
      ),
    );
  }
}

// ================= VIDEO PLAYER PAGE (UNCHANGED) =================

class VideoPlayerPage extends StatefulWidget {
  final String url;
  const VideoPlayerPage({super.key, required this.url});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              if (_showControls)
                Positioned.fill(
                  child: Container(
                    color: Colors.black45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Slider(
                          value: position.inSeconds
                              .clamp(0, duration.inSeconds)
                              .toDouble(),
                          max: duration.inSeconds.toDouble(),
                          onChanged: (v) {
                            _controller.seekTo(
                              Duration(seconds: v.toInt()),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_fmt(position),
                                  style:
                                      const TextStyle(color: Colors.white)),
                              Text(_fmt(duration),
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              if (_showControls)
                IconButton(
                  iconSize: 72,
                  color: Colors.white,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
              Positioned(
                top: 12,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
