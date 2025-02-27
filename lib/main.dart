import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling.dart';

import 'calling.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
//
// class _MyHomePageState extends State<MyHomePage> {
//   Signaling signaling = Signaling();
//   RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   String? roomId;
//   TextEditingController textEditingController = TextEditingController(text: '');
//
//
//
//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     super.dispose();
//   }
//
//
//   bool isVideoEnabled = true;
//   bool isAudioEnabled = true;
//
//   @override
//   void initState(){
//     _localRenderer.initialize();
//     _remoteRenderer.initialize();
//     Future.delayed(Duration(milliseconds: 200),()async{
//       var res = await signaling.openUserMedia(_localRenderer, _remoteRenderer);
//       if(res){
//         setState(() {});
//       }
//     });
//
//     signaling.onAddRemoteStream = ((stream) {
//       _remoteRenderer.srcObject = stream;
//       setState(() {});
//     });
//
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Welcome to Flutter Explained - WebRTC"),
//       ),
//       body: Column(
//         children: [
//           SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   signaling.openUserMedia(_localRenderer, _remoteRenderer);
//                   setState(() {});
//                 },
//                 child: Text("Open camera & microphone"),
//               ),
//               SizedBox(
//                 width: 8,
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   roomId = await signaling.createRoom(_remoteRenderer);
//                   textEditingController.text = roomId!;
//                   setState(() {});
//                 },
//                 child: Text("Create room"),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   // Add roomId
//                   signaling.joinRoom(
//                     textEditingController.text.trim(),
//                     _remoteRenderer
//                   );
//                 },
//                 child: Text("Join room"),
//               ),
//               SizedBox(
//                 width: 8,
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   signaling.hangUp(_localRenderer);
//                 },
//                 child: Text("Hangup"),
//               )
//             ],
//           ),
//           SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               ElevatedButton(
//                 onPressed: ()async{
//                   var newValue = await signaling.toggleVideo(isVideoEnabled);
//                   setState(() {
//                     isVideoEnabled = newValue;
//                   });
//                 },
//                 child: Text(isVideoEnabled ? "Turn Video Off" : "Turn Video On"),
//               ),
//               SizedBox(width: 8),
//               ElevatedButton(
//                 onPressed: ()async{
//                   var newValue = await signaling.toggleAudio(isAudioEnabled);
//                   setState(() {
//                     isAudioEnabled = newValue;
//                   });
//                 },
//                 child: Text(isAudioEnabled ? "Mute" : "Unmute"),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: signaling.hasMultipleCameras
//                 ? () async {
//               await signaling.toggleCamera();
//               setState(() {});
//             }
//                 : null,
//             child: Text("Toggle Camera"),
//           ),
//           SizedBox(height: 8),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
//                   Expanded(child: RTCVideoView(_remoteRenderer)),
//                 ],
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text("Join the following Room: "),
//                 Flexible(
//                   child: TextFormField(
//                     controller: textEditingController,
//                   ),
//                 )
//               ],
//             ),
//           ),
//           SizedBox(height: 8)
//         ],
//       ),
//     );
//   }
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final Signaling signaling = Signaling();
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   final TextEditingController textEditingController = TextEditingController();
//
//   String? roomId;
//   bool isVideoEnabled = true;
//   bool isAudioEnabled = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _localRenderer.initialize();
//     _remoteRenderer.initialize();
//
//     signaling.openUserMedia(_localRenderer, _remoteRenderer).then((res) {
//       if (res) setState(() {});
//     });
//
//     signaling.onAddRemoteStream = (stream) {
//       setState(() => _remoteRenderer.srcObject = stream);
//     };
//   }
//
//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     super.dispose();
//   }
//
//   Widget _buildVideoRenderer(RTCVideoRenderer renderer, {bool isLocal = false}) {
//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.blueAccent, width: 2),
//         ),
//         child: RTCVideoView(renderer, mirror: isLocal, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Flutter WebRTC"), centerTitle: true),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             // Video Streams
//             Expanded(
//               child: Row(
//                 children: [
//                   _buildVideoRenderer(_localRenderer, isLocal: true),
//                   SizedBox(width: 8),
//                   _buildVideoRenderer(_remoteRenderer),
//                 ],
//               ),
//             ),
//             SizedBox(height: 12),
//
//             // Controls
//             Wrap(
//               spacing: 12,
//               runSpacing: 8,
//               alignment: WrapAlignment.center,
//               children: [
//                 OutlinedButton.icon(
//                   onPressed: () async {
//                     roomId = await signaling.createRoom(_remoteRenderer);
//                     textEditingController.text = roomId!;
//                     setState(() {});
//                   },
//                   icon: Icon(Icons.video_call),
//                   label: Text("Create Room"),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed: () => signaling.joinRoom(textEditingController.text.trim(), _remoteRenderer),
//                   icon: Icon(Icons.meeting_room),
//                   label: Text("Join Room"),
//                 ),
//                 OutlinedButton.icon(
//                   onPressed: () => signaling.hangUp(_localRenderer),
//                   icon: Icon(Icons.call_end, color: Colors.red),
//                   label: Text("Hang Up"),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//
//             // Toggle buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 IconButton(
//                   icon: Icon(isVideoEnabled ? Icons.videocam : Icons.videocam_off),
//                   onPressed: () async {
//                     isVideoEnabled = await signaling.toggleVideo(isVideoEnabled);
//                     setState(() {});
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(isAudioEnabled ? Icons.mic : Icons.mic_off),
//                   onPressed: () async {
//                     isAudioEnabled = await signaling.toggleAudio(isAudioEnabled);
//                     setState(() {});
//                   },
//                 ),
//                 if (signaling.hasMultipleCameras)
//                   IconButton(
//                     icon: Icon(Icons.switch_camera),
//                     onPressed: () async {
//                       await signaling.toggleCamera();
//                       setState(() {});
//                     },
//                   ),
//               ],
//             ),
//
//             // Room ID input
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: textEditingController,
//                       decoration: InputDecoration(
//                         labelText: "Room ID",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: () => signaling.joinRoom(textEditingController.text.trim(), _remoteRenderer),
//                     child: Text("Join"),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _MyHomePageState extends State<MyHomePage> {
  // Existing code remains the same...
  final Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final TextEditingController textEditingController = TextEditingController();

  String? roomId;
  bool isVideoEnabled = true;
  bool isAudioEnabled = true;
  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.openUserMedia(_localRenderer, _remoteRenderer).then((res) {
      if (res) setState(() {});
    });

    signaling.onAddRemoteStream = (stream) {
      setState(() => _remoteRenderer.srcObject = stream);
    };
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WebRTC Video Call"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _videoPreviewSection(),
                _callControlsOverlay(),
              ],
            ),
          ),
          _roomControlsSection(),
        ],
      ),
    );
  }

  Widget _videoPreviewSection() {
    return Positioned.fill(
      child: MediaQuery.of(context).size.width < 400
          ? Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black12,
              ),
              child: RTCVideoView(_localRenderer, mirror: true,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,),
            ),
          ),
          if (_remoteRenderer.srcObject != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black12,
                ),
                child: RTCVideoView(_remoteRenderer,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black12,
              ),
              child: RTCVideoView(_localRenderer, mirror: true,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,),
            ),
          ),
          if (_remoteRenderer.srcObject != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black12,
                ),
                child: RTCVideoView(_remoteRenderer,objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,),
              ),
            ),
        ],
      ),
    );
  }

  Widget _callControlsOverlay() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(
                isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                color: isVideoEnabled ? Colors.white : Colors.red,
              ),
              onPressed: () async {
                final newValue = await signaling.toggleVideo(isVideoEnabled);
                setState(() => isVideoEnabled = newValue);
              },
            ),
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.red,
            radius: 28,
            child: IconButton(
              icon: const Icon(Icons.call_end, color: Colors.white),
              onPressed: () => signaling.hangUp(_localRenderer),
              iconSize: 32,
            ),
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: IconButton(
              icon: Icon(
                isAudioEnabled ? Icons.mic : Icons.mic_off,
                color: isAudioEnabled ? Colors.white : Colors.red,
              ),
              onPressed: () async {
                final newValue = await signaling.toggleAudio(isAudioEnabled);
                setState(() => isAudioEnabled = newValue);
              },
            ),
          ),
          if (signaling.hasMultipleCameras) const SizedBox(width: 20),
          if (signaling.hasMultipleCameras)
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: () => signaling.toggleCamera(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _roomControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("New Call"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    roomId = await signaling.createRoom(_remoteRenderer);
                    textEditingController.text = roomId!;
                    setState(() {});
                    _showRoomIdDialog();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text("Join Call"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _showJoinDialog(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoomIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Call Created"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share this code with others to join the call:"),
            const SizedBox(height: 16),
            SelectableText(
              roomId!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: roomId!)),
              child: const Text("Copy to Clipboard"),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join a Call"),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(
            labelText: "Enter Room Code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              signaling.joinRoom(textEditingController.text.trim(), _remoteRenderer);
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Settings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text("Audio Output"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => signaling.toggleSpeaker(),
            ),
            ListTile(
              leading: const Icon(Icons.video_settings),
              title: const Text("Video Quality"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {}, // Add video quality settings implementation
            ),
          ],
        ),
      ),
    );
  }
}

