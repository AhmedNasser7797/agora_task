import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_youtube/pages/call.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({
    Key? key,
  }) : super(key: key);

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController(text: "1234");
  bool _validateError = false;
  ClientRole? _role = ClientRole.Broadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(
              height: 40,
            ),
            Image.network("https://tinyurl.com/2p889y4k"),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                  errorText:
                      _validateError ? "Channel Name is Mandatory" : null,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(width: 1),
                  ),
                  hintText: "Channel Name"),
            ),
            RadioListTile(
                title: const Text("Broadcaster"),
                value: ClientRole.Broadcaster,
                groupValue: _role,
                onChanged: (ClientRole? value) {
                  setState(() {
                    _role = value;
                  });
                }),
            RadioListTile(
                title: const Text("Audience"),
                value: ClientRole.Audience,
                groupValue: _role,
                onChanged: (ClientRole? value) {
                  setState(() {
                    _role = value;
                  });
                }),
            ElevatedButton(
              onPressed: _join,
              child: const Text("Join"),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    if (_channelController.text.isEmpty) {
      _validateError = true;
      setState(() {});
    } else {
      _validateError = false;
      setState(() {});
      await _hundleCameraAndMic(Permission.camera);
      await _hundleCameraAndMic(Permission.microphone);
      await sendToFirebase();
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CallPage(
                    channelName: _channelController.text,
                    role: _role,
                  )));
    }
  }

  Future<void> sendToFirebase() async {
   await FirebaseDatabase.instance.ref("channels").set(_channelController.text);
  }

  Future<void> _hundleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    log(status.toString());
  }
}
