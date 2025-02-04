import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
//                     _remoteRenderer,
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

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  Signaling2 signaling2 = Signaling2();

  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');



  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }


  bool isVideoEnabled = true;
  bool isAudioEnabled = true;

  @override
  void initState(){
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    Future.delayed(Duration(milliseconds: 200),()async{
      // var res = await signaling.openUserMedia(_localRenderer, _remoteRenderer);
      // if(res){
      //   setState(() {});
      // }
      var res2 = await signaling2.openUserMedia(_localRenderer, _remoteRenderer);
      if(res2){
        setState(() {});
      }
    });

    // signaling.onAddRemoteStream = ((stream) {
    //   _remoteRenderer.srcObject = stream;
    //   setState(() {});
    // });

    signaling2.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome to Flutter Explained - WebRTC"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: ()async {
                  textEditingController.text = await signaling2.createRoom();
                },
                child: Text("Create Room 2"),
              ),
              ElevatedButton(
                onPressed: () {
                  signaling2.joinRoom(textEditingController.text.trim());
                },
                child: Text("Join Room 2"),
              ),

              ElevatedButton(
                onPressed: () {
                  signaling2.hangUp();
                },
                child: Text("Hangup"),
              ),
            ],
          ),



          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  signaling.openUserMedia(_localRenderer, _remoteRenderer);
                  setState(() {});
                },
                child: Text("Open camera & microphone"),
              ),
              SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () async {
                  roomId = await signaling.createRoom(_remoteRenderer);
                  textEditingController.text = roomId!;
                  setState(() {});
                },
                child: Text("Create room"),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Add roomId
                  signaling.joinRoom(
                    textEditingController.text.trim(),
                    _remoteRenderer,
                  );
                },
                child: Text("Join room"),
              ),
              SizedBox(
                width: 8,
              ),
              ElevatedButton(
                onPressed: () {
                  signaling.hangUp(_localRenderer);
                },
                child: Text("Hangup"),
              )
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: ()async{
                  var newValue = await signaling.toggleVideo(isVideoEnabled);
                  setState(() {
                    isVideoEnabled = newValue;
                  });
                },
                child: Text(isVideoEnabled ? "Turn Video Off" : "Turn Video On"),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: ()async{
                  var newValue = await signaling.toggleAudio(isAudioEnabled);
                  setState(() {
                    isAudioEnabled = newValue;
                  });
                },
                child: Text(isAudioEnabled ? "Mute" : "Unmute"),
              ),
            ],
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: signaling.hasMultipleCameras
                ? () async {
              await signaling.toggleCamera();
              setState(() {});
            }
                : null,
            child: Text("Toggle Camera"),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                  Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Join the following Room: "),
                Flexible(
                  child: TextFormField(
                    controller: textEditingController,
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 8)
        ],
      ),
    );
  }
}

