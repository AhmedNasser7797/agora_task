import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;

import '../utils/settings.dart';

class CallPage extends StatefulWidget {
  final String? channelName;
  final ClientRole? role;
  const CallPage({Key? key, this.channelName, this.role}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _user = <int>[];
  final _infoStrings = <String>[];
  bool _muted = false;
  bool _viewpanel = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    try{
      initializeCalling();
    }catch(e,s){
      log("****error $e");
      log("****error  $s");
    }
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  //Initialize All The Setup For Agora Video Call
  Future<void> initializeCalling() async {
    if (appId.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

      await _initAgoraRtcEngine();
      _addAgoraEventHandlers();
      var configuration = VideoEncoderConfiguration();
      configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
      configuration.orientationMode = VideoOutputOrientationMode.Adaptative;
      await _engine.setVideoEncoderConfiguration(configuration);
      await _engine.joinChannel(token, widget.channelName!, null, 0);

  }

  //Initialize Agora RTC Engine
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appId);
    await _engine.enableVideo();
    await _engine.enableLocalAudio(_muted);
    await _engine.enableAudio();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role!);
  }

  //Agora Events Handler To Implement Ui/UX Based On Your Requirements
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError:$code ${code}';
          _infoStrings.add(info);
        });
        log('onError:$code ${code}');
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          // _joined = true;
          final info = 'onJoinChannel: $channel, uid: $uid';
          _infoStrings.add(info);
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _user.add(uid);
          // _remoteUid = uid;
        });
      },
      userOffline: (uid, elapsed) async {
        if (elapsed == UserOfflineReason.Dropped) {
          // Wakelock.disable();
        } else {
          setState(() {
            final info = 'userOffline: $uid';
            _infoStrings.add(info);
            _user.remove(uid);
            // _remoteUid = null;
            // _timerKey?.currentState?.cancelTimer();
          });
        }
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          _infoStrings.add(info);
        });
      },
      // connectionStateChanged: (type, reason) async {
      //   if (type == ConnectionStateType.Connected) {
      //     setState(() {
      //       _reConnectingRemoteView = false;
      //     });
      //   } else if (type == ConnectionStateType.Reconnecting) {
      //     setState(() {
      //       _reConnectingRemoteView = true;
      //     });
      //   }
      // },
      // remoteVideoStats: (remoteVideoStats) {
      //   if (remoteVideoStats.receivedBitrate == 0) {
      //     setState(() {
      //       _reConnectingRemoteView = true;
      //     });
      //   } else {
      //     setState(() {
      //       _reConnectingRemoteView = false;
      //     });
      //   }
      // },
    ));
  }

  Widget _viewRow() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(const rtc_local_view.SurfaceView());
    }
    for (var uid in _user) {
      list.add(rtc_remote_view.SurfaceView(
        uid: uid,
        channelId: widget.channelName!,
      ));
    }
    final views = list;
    return Column(
      children: List.generate(
        views.length,
        (index) => Expanded(
          child: views[index],
        ),
      ),
    );
  }
  // Ui & UX For Bottom Portion (Switch Camera,Video On/Off,Mic On/Off)
  Widget _bottomPortionWidget() => Container(
    margin: const EdgeInsets.symmetric(
        horizontal: 40),
    alignment: Alignment.bottomCenter,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        RawMaterialButton(
          onPressed: (){
            _engine.switchCamera();
          },
          child: const Icon(
           Icons.switch_camera,
            color: Colors.blueAccent,
            size: 20,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor:
         Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        RawMaterialButton(
          onPressed: ()=>Navigator.pop(context),
          child: const Icon(Icons.call_end ,
            color: Colors.white,
            size: 35,
          ),
          shape:const CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.redAccent,
          padding: const EdgeInsets.all(12),
        ),
        RawMaterialButton(
          onPressed: (){
            setState(() {
              _muted=!_muted;
            });
            _engine.muteLocalAudioStream(_muted);
          },
          child: Icon(
            _muted ? Icons.mic_off : Icons.mic,
            color: _muted?Colors.white:Colors.blueAccent,
            size: 20,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: _muted
              ? Colors.blueAccent
              : Colors.white,
          padding: const EdgeInsets.all(12),
        ),
      ],
    ),
  );

  Widget _panel(){
    return Visibility(
        visible: _viewpanel,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: ListView.builder(itemBuilder: (contex,int index ){
                if(_infoStrings.isEmpty)return const Text("null");
                return Padding(padding: const EdgeInsets.symmetric(vertical: 3,horizontal: 10),child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2,horizontal: 5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Text(_infoStrings[index],style: const TextStyle(
                        color: Colors.blueGrey,
                      ),),
                    ),),
                  ],
                ),);

              }),
            ),
          ),
        ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Agora"),
        centerTitle: true,
      actions: [
        IconButton(onPressed: (){
          setState(() {
            _viewpanel=!_viewpanel;
          });
        }, icon: const Icon(Icons.info_outline),),
      ],
      ),
      body: Center(
        child: Stack(
          children: [
            _viewRow(),
            _panel(),
            _bottomPortionWidget(),
          ],
        ),
      ),
    );
  }
}
