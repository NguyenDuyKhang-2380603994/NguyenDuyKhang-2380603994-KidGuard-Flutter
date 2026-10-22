
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/approval_service.dart';

class ApprovedContentScreen extends StatefulWidget {
  final int approvalId;
  final String title;
  final String approvedUrl;
  final DateTime expiresAtUtc;

  const ApprovedContentScreen({
    super.key,
    required this.approvalId,
    required this.title,
    required this.approvedUrl,
    required this.expiresAtUtc,
  });

  @override
  State<ApprovedContentScreen> createState() =>
      _ApprovedContentScreenState();
}

class _ApprovedContentScreenState
    extends State<ApprovedContentScreen>
    with WidgetsBindingObserver {

  WebViewController? _web;
  YoutubePlayerController? _youtube;
  Timer? _timer;

  late final Uri _approvedUri;

  int _secondsLeft = 0;
  bool _initializing = true;
  bool _pageLoading = true;
  bool _checking = false;
  bool _closing = false;

  String? _error;

  // Kiểm tra tên miền thuộc YouTube
  bool _isYoutube(Uri uri) {
    final host = uri.host.toLowerCase();

    return host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtu.be' ||
        host == 'www.youtu.be';
  }

  // Kiểm soát URL được mở trong WebView
  bool _isAllowedUrl(Uri requested) {
    if (requested.scheme != 'https') {
      return false;
    }

    // Parent cho phép trang YouTube:
    // chỉ duyệt bên trong YouTube
    if (_isYoutube(_approvedUri)) {
      return _isYoutube(requested);
    }

    // Website khác: chỉ URL đã được duyệt
    final allowed = _approvedUri.replace(
      fragment: '',
      path: _approvedUri.path.isEmpty
          ? '/'
          : _approvedUri.path,
    );

    final target = requested.replace(
      fragment: '',
      path: requested.path.isEmpty
          ? '/'
          : requested.path,
    );

    return allowed == target;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _approvedUri = Uri.parse(widget.approvedUrl);

    _secondsLeft = _remainingSeconds();

    _initializeContent();

    // Kiểm tra đồng hồ mỗi giây
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted || _closing) return;

        setState(() {
          _secondsLeft = _remainingSeconds();
        });

        if (_secondsLeft <= 0) {
          _close('Viewing time has expired.');
          return;
        }

        // Cứ 10 giây kiểm tra quyền với Backend
        if (timer.tick % 10 == 0) {
          _verifyAccess();
        }
      },
    );
  }

  int _remainingSeconds() {
    final difference = widget.expiresAtUtc
        .toUtc()
        .difference(DateTime.now().toUtc())
        .inSeconds;

    return difference > 0 ? difference : 0;
  }

  // Xác nhận quyền trước khi tải trang
  Future<void> _initializeContent() async {
    try {
      await ApprovalService.checkAccess(
        widget.approvalId,
      );

      if (!mounted) return;

      String? videoId;

      if (_isYoutube(_approvedUri)) {
        videoId = YoutubePlayerController
            .convertUrlToId(widget.approvedUrl);
      }

      if (videoId != null) {
        // LINK VIDEO YOUTUBE CỤ THỂ
        _youtube = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: false,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: false,
            strictRelatedVideos: true,
            playsInline: true,
          ),
        );
      } else {
        // TRANG CHỦ YOUTUBE HOẶC WEBSITE THƯỜNG
        final controller = WebViewController();

        await controller.setJavaScriptMode(
          JavaScriptMode.unrestricted,
        );

        await controller.setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) {
                setState(() => _pageLoading = true);
              }
            },

            onPageFinished: (_) {
              if (mounted) {
                setState(() => _pageLoading = false);
              }
            },

            onWebResourceError: (error) {
              if (error.isForMainFrame == true &&
                  mounted) {
                setState(() {
                  _pageLoading = false;
                  _error =
                  'Cannot load website:\n'
                      '${error.description}';
                });
              }
            },

            onNavigationRequest: (request) {
              if (!request.isMainFrame) {
                return NavigationDecision.navigate;
              }

              final requested =
              Uri.tryParse(request.url);

              if (requested != null &&
                  _isAllowedUrl(requested)) {
                return NavigationDecision.navigate;
              }

              if (mounted) {
                setState(() {
                  _pageLoading = false;
                  _error =
                  'This page is outside the '
                      'content approved by Parent.';
                });
              }

              return NavigationDecision.prevent;
            },
          ),
        );

        _web = controller;

        await controller.loadRequest(_approvedUri);
      }

      if (!mounted) return;

      setState(() {
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _initializing = false;
        _error = e.toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  // Kiểm tra Parent có thu hồi quyền không
  Future<void> _verifyAccess() async {
    if (_checking || _closing) return;

    _checking = true;

    try {
      await ApprovalService.checkAccess(
        widget.approvalId,
      );
    } catch (_) {
      if (mounted) {
        _close(
          'Permission expired, revoked '
              'or connection lost.',
        );
      }
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final player = _youtube;

      if (player != null) {
        unawaited(player.pauseVideo());
      }
    }

    if (state == AppLifecycleState.resumed) {
      _verifyAccess();
    }
  }

  void _close(String message) {
    if (!mounted || _closing) return;

    _closing = true;
    _timer?.cancel();

    Navigator.of(context).pop(message);
  }

  @override
  void dispose() {
    _timer?.cancel();

    final player = _youtube;

    if (player != null) {
      unawaited(player.close());
    }

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mm = (_secondsLeft ~/ 60)
        .toString()
        .padLeft(2, '0');

    final ss = (_secondsLeft % 60)
        .toString()
        .padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FC),

        title: Text(
          widget.title,
          overflow: TextOverflow.ellipsis,
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                '$mm:$ss',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: _initializing
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 15),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )

      // VIDEO YOUTUBE: PLAYER NHÚNG
          : _youtube != null
          ? ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Approved YouTube Video',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          YoutubePlayer(
            controller: _youtube!,
            aspectRatio: 16 / 9,
          ),

          const SizedBox(height: 18),

          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Your viewing time is controlled '
                'by KidGuard and Parent Approval.',
            style: TextStyle(
              color: Colors.blueGrey,
            ),
          ),
        ],
      )

      // WEBSITE THƯỜNG / YOUTUBE HOME
          : _web != null
          ? Stack(
        children: [
          WebViewWidget(
            controller: _web!,
          ),

          if (_pageLoading)
            const Center(
              child:
              CircularProgressIndicator(),
            ),
        ],
      )
          : const Center(
        child: Text(
          'Content unavailable',
        ),
      ),
    );
  }
}
