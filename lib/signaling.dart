import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef void StreamStateCallback(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  bool hasMultipleCameras = false;

  // Create Room (Caller)
  Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
    final db = FirebaseFirestore.instance;
    final roomRef = db.collection('rooms').doc();
    bool answerProcessed = false;
    StreamSubscription? roomSubscription;
    StreamSubscription? candidateSubscription;

    try {
      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();

      peerConnection?.onTrack = (RTCTrackEvent event) {
        print("🚀 onTrack event triggered: ${event.track.kind}");
        if (event.track.kind == "video") {
          remoteStream = event.streams.first;
          onAddRemoteStream?.call(remoteStream!);
          print("✅ Remote video stream added successfully");
        }
      };

      // Add local streams
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // ICE Candidate handling
      final callerCandidates = roomRef.collection('callerCandidates');
      peerConnection?.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null || candidate.candidate!.isEmpty) return;
        callerCandidates.add(candidate.toMap());
      };

      // Create and set offer
      final offer = await peerConnection!.createOffer();
      await peerConnection!.setLocalDescription(offer);

      await roomRef.set({
        'offer': offer.toMap(),
        // 'answer': FieldValue.delete() // Clear previous answers
      });

      // Remote answer listener
      roomSubscription = roomRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists || answerProcessed) return;

        final data = snapshot.data()!;
        if (data['answer'] != null &&
            peerConnection?.signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {

          answerProcessed = true;
          final answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

          try {
            await peerConnection?.setRemoteDescription(answer);
            print('✅ Remote answer set successfully');
            roomSubscription?.cancel();
          } catch (e) {
            print('❌ Error setting answer: $e');
          }
        }
      });

      // Remote ICE candidates listener
      candidateSubscription = roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            peerConnection!.addCandidate(RTCIceCandidate(
              data['candidate'],
              data['sdpMid']!,
              data['sdpMLineIndex']!,
            ));
          }
        }
      });


      return roomRef.id;
    } catch (e) {
      _cleanupResources([roomSubscription, candidateSubscription]);
      rethrow;
    }
  }

// Join Room (Callee)
  Future<void> joinRoom(String roomId,RTCVideoRenderer remoteVideo) async {
    final db = FirebaseFirestore.instance;
    final roomRef = db.collection('rooms').doc(roomId);
    StreamSubscription? candidateSubscription;

    try {
      final snapshot = await roomRef.get();
      if (!snapshot.exists || !snapshot.data()!.containsKey('offer')) {
        throw Exception('Room not found or missing offer');
      }

      peerConnection = await createPeerConnection(configuration);
      registerPeerConnectionListeners();
      peerConnection?.onTrack = (RTCTrackEvent event) {
        print("🚀 onTrack event triggered: ${event.track.kind}");
        if (event.track.kind == "video") {
          remoteStream = event.streams.first;
          onAddRemoteStream?.call(remoteStream!);
          print("✅ Remote video stream added successfully");
        }
      };
      // Add local streams
      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // ICE Candidate handling
      final calleeCandidates = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null || candidate.candidate!.isEmpty) return;
        calleeCandidates.add(candidate.toMap());
      };

      // Process offer
      final offerData = snapshot.data()!['offer'] as Map<String, dynamic>;
      final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);
      await peerConnection!.setRemoteDescription(offer);

      // Create and send answer
      final answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);
      await roomRef.update({'answer': answer.toMap()});

      // Listen for caller ICE candidates
      candidateSubscription = roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data()!;
            peerConnection!.addCandidate(RTCIceCandidate(
              data['candidate'],
              data['sdpMid']!,
              data['sdpMLineIndex']!,
            ));
          }
        }
      });

      // peerConnection?.onTrack = (RTCTrackEvent event) {
      //   if (event.streams.isEmpty) return;
      //   event.streams[0].getTracks().forEach((track) {
      //     remoteStream?.addTrack(track);
      //     onAddRemoteStream?.call(event.streams.first);
      //     remoteStream = event.streams.first;
      //   });
      // };

    } catch (e) {
      _cleanupResources([candidateSubscription]);
      rethrow;
    }
  }

  void _cleanupResources(List<StreamSubscription?> subscriptions) {
    for (final sub in subscriptions) {
      sub?.cancel();
    }
    peerConnection?.close();
    peerConnection = null;
  }

  Future<void> toggleCamera() async {
    if (localStream == null) return;

    // Get the first video track
    var videoTrack = localStream!.getVideoTracks().first;

    // Check if switching is supported
    if (videoTrack.kind == 'video' && videoTrack is MediaStreamTrack) {
      try {
        await Helper.switchCamera(videoTrack); // This switches between front and back cameras
      } catch (e) {
        print("Error switching camera: $e");
      }
    }
  }

  // Update openUserMedia to detect multiple cameras
  Future<bool> openUserMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo,) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    // Detect available cameras
    final devices = await navigator.mediaDevices.enumerateDevices();
    final videoDevices = devices.where((d) => d.kind == 'videoinput').toList();
    hasMultipleCameras = videoDevices.length >= 2;

    localVideo.srcObject = stream;
    localStream = stream;
    remoteVideo.srcObject = await createLocalMediaStream('remote');
    // toggleSpeaker();
    return true;
  }

  Future<bool> toggleVideo(isVideoEnabled)async {
    if (localStream != null) {
      for (var track in localStream!.getVideoTracks()) {
        track.enabled = !isVideoEnabled;
      }
    }
    return !isVideoEnabled;
  }

  Future<bool> toggleAudio(isAudioEnabled) async{
    if (localStream != null) {
      for (var track in localStream!.getAudioTracks()) {
        track.enabled = !isAudioEnabled;
      }
    }
    return !isAudioEnabled;
  }

  Future<void> toggleSpeaker() async {

    try {
      // if (isSpeakerOn) {
        await Helper.selectAudioOutput('speaker'); // Switch to speakerphone
      // } else {
      //   await Helper.selectAudioOutput('earpiece'); // Switch to earpiece
      // }
    } catch (e) {
      print('Error toggling speaker: $e');
    }
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      calleeCandidates.docs.forEach((document) => document.reference.delete());

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      callerCandidates.docs.forEach((document) => document.reference.delete());

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;

    };
  }
}

// Future<String> createRoom(RTCVideoRenderer remoteRenderer) async {
//   FirebaseFirestore db = FirebaseFirestore.instance;
//   DocumentReference roomRef = db.collection('rooms').doc();
//
//   print('Create PeerConnection with configuration: $configuration');
//
//   peerConnection = await createPeerConnection(configuration);
//
//   registerPeerConnectionListeners();
//
//   localStream?.getTracks().forEach((track) {
//     peerConnection?.addTrack(track, localStream!);
//   });
//
//   // Code for collecting ICE candidates below
//   var callerCandidatesCollection = roomRef.collection('callerCandidates');
//
//   peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
//     print('Got candidate: ${candidate.toMap()}');
//     callerCandidatesCollection.add(candidate.toMap());
//   };
//   // Finish Code for collecting ICE candidate
//
//   // Add code for creating a room
//   RTCSessionDescription offer = await peerConnection!.createOffer();
//   await peerConnection!.setLocalDescription(offer);
//   print('Created offer: $offer');
//
//   Map<String, dynamic> roomWithOffer = {
//     'offer': offer.toMap(),
//   };
//
//   await roomRef.set(roomWithOffer);
//   var roomId = roomRef.id;
//   print('New room created with SDK offer. Room ID: $roomId');
//   currentRoomText = 'Current room is $roomId - You are the caller!';
//   // Created a Room
//
//   peerConnection?.onTrack = (RTCTrackEvent event) {
//     print('Got remote track: ${event.streams[0]}');
//
//     event.streams[0].getTracks().forEach((track) {
//       print('Add a track to the remoteStream $track');
//       remoteStream?.addTrack(track);
//
//     });
//   };
//
//   // Listening for remote session description below
//   roomRef.snapshots().listen((snapshot) async {
//     print('Got updated room: ${snapshot.data()}');
//
//     Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
//     if (peerConnection?.getRemoteDescription() == null &&
//         data['answer'] != null) {
//       var answer = RTCSessionDescription(
//         data['answer']['sdp'],
//         data['answer']['type'],
//       );
//
//       print("Someone tried to connect");
//       await peerConnection?.setRemoteDescription(answer);
//     }
//   });
//   // Listening for remote session description above
//
//   // Listen for remote Ice candidates below
//   roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
//     snapshot.docChanges.forEach((change) {
//       if (change.type == DocumentChangeType.added) {
//         Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
//         print('Got new remote ICE candidate: ${jsonEncode(data)}');
//         peerConnection!.addCandidate(
//           RTCIceCandidate(
//             data['candidate'],
//             data['sdpMid'],
//             data['sdpMLineIndex'],
//           ),
//         );
//       }
//     });
//   });
//   // Listen for remote ICE candidates above
//   toggleSpeaker();
//   return roomId;
// }
//
// Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
//   FirebaseFirestore db = FirebaseFirestore.instance;
//   print(roomId);
//   DocumentReference roomRef = db.collection('rooms').doc('$roomId');
//   var roomSnapshot = await roomRef.get();
//   print('Got room ${roomSnapshot.exists}');
//
//   if (roomSnapshot.exists) {
//     print('Create PeerConnection with configuration: $configuration');
//     peerConnection = await createPeerConnection(configuration);
//
//     registerPeerConnectionListeners();
//
//     localStream?.getTracks().forEach((track) {
//       peerConnection?.addTrack(track, localStream!);
//     });
//
//     // Code for collecting ICE candidates below
//     var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
//     peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
//       if (candidate == null) {
//         print('onIceCandidate: complete!');
//         return;
//       }
//       print('onIceCandidate: ${candidate.toMap()}');
//       calleeCandidatesCollection.add(candidate.toMap());
//     };
//     // Code for collecting ICE candidate above
//
//     peerConnection?.onTrack = (RTCTrackEvent event) {
//       print('Got remote track: ${event.streams[0]}');
//       event.streams[0].getTracks().forEach((track) {
//         print('Add a track to the remoteStream: $track');
//         remoteStream?.addTrack(track);
//       });
//     };
//
//     // Code for creating SDP answer below
//     var data = roomSnapshot.data() as Map<String, dynamic>;
//     print('Got offer $data');
//     var offer = data['offer'];
//     await peerConnection?.setRemoteDescription(
//       RTCSessionDescription(offer['sdp'], offer['type']),
//     );
//     var answer = await peerConnection!.createAnswer();
//     print('Created Answer $answer');
//
//     await peerConnection!.setLocalDescription(answer);
//
//     Map<String, dynamic> roomWithAnswer = {
//       'answer': {'type': answer.type, 'sdp': answer.sdp}
//     };
//
//     await roomRef.update(roomWithAnswer);
//     // Finished creating SDP answer
//
//     // Listening for remote ICE candidates below
//     roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
//       snapshot.docChanges.forEach((document) {
//         var data = document.doc.data() as Map<String, dynamic>;
//         print(data);
//         print('Got new remote ICE candidate: $data');
//         peerConnection!.addCandidate(
//           RTCIceCandidate(
//             data['candidate'],
//             data['sdpMid'],
//             data['sdpMLineIndex'],
//           ),
//         );
//       });
//     });
//   }
//   toggleSpeaker();
// }
class Signaling2 {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };
  final String serverUrl = 'https://phonecall-josu.onrender.com';
  // final String serverUrl = "http://localhost:3000"; // Change to your server IP if needed
  final Dio dio = Dio();

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;

  Function(MediaStream stream)? onAddRemoteStream;

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }

  Future<bool> openUserMedia(RTCVideoRenderer localVideo, RTCVideoRenderer remoteVideo,) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    // Detect available cameras
    // final devices = await navigator.mediaDevices.enumerateDevices();
    // final videoDevices = devices.where((d) => d.kind == 'videoinput').toList();
    // hasMultipleCameras = videoDevices.length >= 2;
    //
    // if (videoDevices.isNotEmpty) {
    //   _currentCameraId = videoDevices.first.deviceId;
    // }

    localVideo.srcObject = stream;
    localStream = stream;
    remoteVideo.srcObject = await createLocalMediaStream('remote');
    // toggleSpeaker();
    return true;
  }

  Future<String> createRoom() async {
    peerConnection = await createPeerConnection(configuration);
    print("PeerConnection created: ${peerConnection}");

    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print("Caller: Remote stream added - ${event.streams[0].id}");
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
      }
    };

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });


    peerConnection!.onIceCandidate = (candidate) async {
      print("Local ICE Candidate: ${candidate.toMap()}");

      if (roomId != null) {
        try{
          await dio.post("$serverUrl/room/$roomId/candidate", data: candidate.toMap());
        }catch(r){
          print('s');
          print(r);
        }
      }
    };

    var offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    try{
      var response = await dio.post("$serverUrl/create-room", data: offer.toMap());
      roomId = response.data["roomId"];
    }catch(r){
      print('ss');
      print(r);
    }

    // var offer = await peerConnection!.createOffer();
    // await peerConnection!.setLocalDescription(offer);
    // var response = await dio.post("$serverUrl/create-room", data: offer.toMap());
    // roomId = response.data["roomId"];

    print(roomId);
    return roomId!;
  }

  Future<void> joinRoom(String id) async {
    roomId = id;
    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        print("Callee: Remote stream added - ${event.streams[0].id}");
        remoteStream = event.streams[0];
        onAddRemoteStream?.call(remoteStream!);
      }
    };

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });
    // peerConnection!.onIceCandidate = (candidate) async {
    //   await dio.post("$serverUrl/room/$roomId/candidate", data: candidate.toMap());
    // };
    peerConnection!.onIceCandidate = (candidate) async {
      print("Local ICE Candidate: ${candidate.toMap()}");

      if (roomId != null) {
        try{
          await dio.post("$serverUrl/room/$roomId/candidate", data: candidate.toMap());
        }catch(r){
          print('sss');
          print(r);
        }
      }
    };


    var response = await dio.get("$serverUrl/room/$roomId");
    var offer = response.data["offer"];

    if (offer != null) {

      await peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer["sdp"], offer["type"]),
      );

      var answer = await peerConnection!.createAnswer();
      await peerConnection!.setLocalDescription(answer);

      try{
        await dio.post("$serverUrl/room/$roomId/answer", data: answer.toMap());
      }catch(r){
        print('ssss');
        print(r);
      }
    }



    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    while (peerConnection != null &&
        peerConnection!.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
      try{
        var response = await dio.get("$serverUrl/room/$roomId/candidates");
        print(response.data);
        print('sssssaaaa');
        for (var candidate in response.data) {
          print("Adding Remote ICE Candidate: $candidate");
          await peerConnection!.addCandidate(RTCIceCandidate(
            candidate["candidate"],
            candidate["sdpMid"],
            candidate["sdpMLineIndex"],
          ));
        }
      }catch(r){
        print('sssss');
        print(r);
      }

      await Future.delayed(Duration(seconds: 5)); // Poll every second
    }
    print("ICE candidate fetching stopped as connection is established.");
  }


  void hangUp() {
    peerConnection?.close();
    peerConnection = null;
    roomId = null;
  }
}
