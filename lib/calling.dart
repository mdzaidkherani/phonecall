import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phonecall/videocallScreen.dart';


class VoiceCallScreen extends StatefulWidget {
  @override
  _VoiceCallScreenState createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final TextEditingController _calleeIdController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  DocumentReference<Map<String, dynamic>>? _roomRef;
  String _myUserId = "user2"; // Replace with actual user ID
  String _calleeId = "";

  @override
  void initState() {
    super.initState();
    // _checkPermissions();
    _initializeWebRTC();
    _listenForIncomingCalls();
  }
  _checkPermissions()async{
    await Permission.camera.request();
    await Permission.microphone.request();
  }
  Future<void> _initializeWebRTC() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    _peerConnection = await createPeerConnection(config);

    // Add ICE candidates
    _peerConnection?.onIceCandidate = (candidate) {
      if (candidate != null) {
        _roomRef?.collection('candidates').add(candidate.toMap());
      }
    };
  }

  Future<void> _makeCall(String calleeId) async {
    _calleeId = calleeId;
    _roomRef = _db.collection('rooms').doc();

    // Create the local stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    _peerConnection!.addStream(_localStream!);

    // Create offer
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Save offer and call status to Firestore
    await _roomRef?.set({
      'callerId': _myUserId,
      'calleeId': calleeId,
      'offer': offer.toMap(),
      'callStatus': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Listen for the answer
    _roomRef?.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data?['answer'] != null) {
        final answer = RTCSessionDescription(
          data!['answer']['sdp'],
          data['answer']['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
      }

      // Handle call rejection
      if (data?['callStatus'] == 'rejected') {
        print("Call rejected by callee.");
      }
    });

    // Navigate to the video call screen for the caller
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(
          peerConnection: _peerConnection!,
          localStream: _localStream!,
        ),
      ),
    );
  }

  // Future<void> _makeCall(String calleeId) async {
  //   _calleeId = calleeId;
  //   _roomRef = _db.collection('rooms').doc();
  //
  //   // Create offer
  //   final offer = await _peerConnection!.createOffer();
  //   await _peerConnection!.setLocalDescription(offer);
  //
  //   // Save offer and call status to Firestore
  //   await _roomRef?.set({
  //     'callerId': _myUserId,
  //     'calleeId': calleeId,
  //     'offer': offer.toMap(),
  //     'callStatus': 'calling',
  //     'timestamp': FieldValue.serverTimestamp(),
  //   });
  //
  //   // Listen for the answer
  //   _roomRef?.snapshots().listen((snapshot) async {
  //     final data = snapshot.data();
  //     if (data?['answer'] != null) {
  //       final answer = RTCSessionDescription(
  //         data!['answer']['sdp'],
  //         data['answer']['type'],
  //       );
  //       await _peerConnection!.setRemoteDescription(answer);
  //     }
  //
  //     // Handle call rejection
  //     if (data?['callStatus'] == 'rejected') {
  //       print("Call rejected by callee.");
  //     }
  //   });
  // }

  Future<void> _listenForIncomingCalls() async {
    _db
        .collection('rooms')
        .where('calleeId', isEqualTo: _myUserId)
        .where('callStatus', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) {
          print(snapshot.docs.length);
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final callerId = data['callerId'];
        final roomId = doc.id;

        // Show an incoming call dialog
        _showIncomingCallDialog(callerId, roomId);
      }
    });
  }

  void _showIncomingCallDialog(String callerId, String roomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Incoming Call"),
          content: Text("You have an incoming call from $callerId."),
          actions: [
            TextButton(
              onPressed: () {
                _acceptCall(roomId);
                // Navigator.of(context).pop();
              },
              child: Text("Accept"),
            ),
            TextButton(
              onPressed: () {
                _rejectCall(roomId);
                Navigator.of(context).pop();
              },
              child: Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptCall(String roomId) async {
    print('debug 1');
    _roomRef = _db.collection('rooms').doc(roomId);
    print('debug 2');
    final snapshot = await _roomRef?.get();
    print('debug 3');
    if (snapshot?.exists == true) {
      print('debug 4');
      final data = snapshot?.data();
      print('debug 5');
      final offer = data?['offer'];
      print('debug 6');
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      print('debug 7');

      // Create answer
      final answer = await _peerConnection!.createAnswer();
      print('debug 8');
      await _peerConnection!.setLocalDescription(answer);
      print('debug 9');


      // Save answer in Firestore
      await _roomRef?.update({
        'answer': answer.toMap(),
        'callStatus': 'connected',
      });
      print('debug 10');
      // Start the video call
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });
      print('debug 11');
      _peerConnection!.addStream(_localStream!);
      print('debug 12');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            peerConnection: _peerConnection!,
            localStream: _localStream!,
          ),
        ),
      );
    }
  }

  // Future<void> _acceptCall(String roomId) async {
  //   _roomRef = _db.collection('rooms').doc(roomId);
  //
  //   final snapshot = await _roomRef?.get();
  //   if (snapshot?.exists == true) {
  //     final data = snapshot?.data();
  //     final offer = data?['offer'];
  //
  //     await _peerConnection?.setRemoteDescription(
  //       RTCSessionDescription(offer['sdp'], offer['type']),
  //     );
  //
  //     // Create answer
  //     final answer = await _peerConnection!.createAnswer();
  //     await _peerConnection!.setLocalDescription(answer);
  //
  //     // Save answer in Firestore
  //     await _roomRef?.update({
  //       'answer': answer.toMap(),
  //       'callStatus': 'connected',
  //     });
  //   }
  // }

  Future<void> _rejectCall(String roomId) async {
    final roomRef = _db.collection('rooms').doc(roomId);
    await roomRef.update({'callStatus': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voice Call")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _calleeIdController,
              decoration: InputDecoration(labelText: "Callee ID"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _makeCall(_calleeIdController.text),
              child: Text("Call"),
            ),
          ],
        ),
      ),
    );
  }
}
