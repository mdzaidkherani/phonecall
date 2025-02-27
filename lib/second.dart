import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final RTCPeerConnection peerConnection;
  final MediaStream localStream;
  final MediaStream? remoteStream;

  const VideoCallScreen({
    required this.peerConnection,
    required this.localStream,
    this.remoteStream,
    Key? key,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RTCVideoRenderer _localRenderer;
  late RTCVideoRenderer _remoteRenderer;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _setupStreams();
  }

  Future<void> _initializeRenderers() async {
    try {
      _localRenderer = RTCVideoRenderer();
      await _localRenderer.initialize();

      _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer.initialize();

      _localRenderer.srcObject = widget.localStream;

      if (widget.remoteStream != null) {
        _remoteRenderer.srcObject = widget.remoteStream!;
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      print("Error initializing renderers: $e");
      // Handle errors (e.g., show a snackbar or log to an analytics service)
    }
  }

  void _setupStreams() {
    widget.peerConnection.onAddStream = (MediaStream stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  void _endCall() {
    // Stop all tracks of the local stream
    widget.localStream.getTracks().forEach((track) => track.stop());

    // Close the peer connection
    widget.peerConnection.close();

    // Navigate back to the previous screen
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    widget.localStream.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // Remote Video
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          // Local Video (Picture-in-Picture)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          // Call Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _endCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
