import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:swed/services/open_ai_service.dart';
import 'package:http/http.dart' as http;
import 'package:swed/util/internet_connectivity.dart';

import '../util/pallete.dart';

class DallEScreen extends StatefulWidget {
  String? prompt;

  DallEScreen({super.key, this.prompt});

  @override
  State<DallEScreen> createState() => _DallEScreenState();
}

class _DallEScreenState extends State<DallEScreen> {
  final speechToText = SpeechToText();
  OpenAIService openAIService = OpenAIService();
  String? imageUrl;
  bool showProgressBar = false;
  bool isUserTyping = false;
  TextEditingController textEditingController = TextEditingController();
  var random = Random();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initTextToSpeech();
    if (widget.prompt != null) {
      loadImage();
    }
    textEditingController.addListener(getTextFromTextField);
  }

  Future<void> initTextToSpeech() async {
    await speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await speechToText.listen(
        onResult: _onSpeechResult, listenFor: Duration(minutes: 1));
    setState(() {
      showProgressBar = true;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    print(result.recognizedWords);
    InternetConnectivity connectivity = InternetConnectivity();
    if (result.finalResult) {
      if (await connectivity.checkInternetConnection()) {
        widget.prompt = result.recognizedWords;
        print("final word ${widget.prompt}");
        if (widget.prompt != null && widget.prompt!.isNotEmpty) {
          loadImage();
        }
      }
      else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "No internet connection available",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFFe91e63),
        ));
      }
    }
    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {
      showProgressBar = true;
    });
  }

  void getTextFromTextField() {
    String text = textEditingController.text;
    if (text.isNotEmpty) {
      isUserTyping = true;
    } else {
      isUserTyping = false;
    }
    setState(() {});
  }

  void loadImage() async {
    setState(() {
      showProgressBar = true;
    });
    try {
      http.Response res = await openAIService.dallAPI2(widget.prompt!);
      print(res.body);
      if (res.statusCode == 200) {
        String content = jsonDecode(res.body)["data"][0]['url'];
        imageUrl = content.trim();
        print("content $content");
      } else {
        widget.prompt = null;
        String errorMessage = "";
        if (jsonDecode(res.body)["error"]["message"]) {
          errorMessage = jsonDecode(res.body)["error"]["message"];
        } else {
          errorMessage = res.body.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error - $errorMessage"),
        ));
      }
    } catch (e) {
      print(e);

      String errorMessage = "Error occurred - ${e.toString()}";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
      ));
    }
    setState(() {
      showProgressBar = false;
      imageUrl;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          title:const Text("Image Generator")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(
            height: 5,
          ),
          showProgressBarNothingImage(),
          Container(
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              padding:const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                      minLines: 1,
                      scrollController:
                          ScrollController(keepScrollOffset: true),
                      scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom +
                              16 * 4),
                      controller: textEditingController,
                      decoration: InputDecoration(
                        hintText: 'Enter a Image Prompt',
                        hintStyle: const TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w300),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                      ),
                    ),
                  ),
                  Container(
                      margin:const EdgeInsets.only(left: 5),
                      child: showSendOrRecordingButton()),
                ],
              )),
        ],
      ),
    );
  }

  Widget showProgressBarNothingImage() {
    if (widget.prompt == null) {
      return Text(
        'No Image available to Preview',
        style: TextStyle(color: Colors.grey[500]),
      );
    }
    if (showProgressBar) {
      return const CircularProgressIndicator();
    } else {
      return Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 1.5,
            padding: const EdgeInsets.all(15),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15), // Adjust the radius as needed
              ),
              clipBehavior: Clip.antiAlias,
              elevation: 5.0,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.fill,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                onPressed: () {
                  _saveImage(context);
                },
                icon: const Icon(Icons.download, size: 26, color: Colors.white),
                style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: Pallete.assistantCircleColorCircle),
              )),
        ],
      );
    }
  }

  Widget showSendOrRecordingButton() {
    if (isUserTyping) {
      return IconButton(
        padding:const EdgeInsets.all(12),
        onPressed: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          FocusScope.of(context).unfocus();
          InternetConnectivity connectivity = InternetConnectivity();
          if (await connectivity.checkInternetConnection()) {
            widget.prompt = textEditingController.text;
            loadImage();
          } else {
            scaffoldMessenger.showSnackBar( const SnackBar(
              content: Text(
                "No internet connection available",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Color(0xFFe91e63),
            ));
          }
        },
        icon: const Icon(Icons.send, size: 26, color: Colors.white),
        style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Pallete.assistantCircleColorCircle),
      );
    } else if (speechToText.isListening) {
      return IconButton(
        padding:const EdgeInsets.all(12),
        onPressed: () {
          stopListening();
        },
        icon: const Icon(Icons.stop, size: 26, color: Colors.white),
        style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Pallete.assistantCircleColorCircle),
      );
    } else {
      return IconButton(
        padding:const EdgeInsets.all(12),
        onPressed: () {
          _startListening();
        },
        icon: const Icon(Icons.mic, size: 26, color: Colors.white),
        style: IconButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Pallete.assistantCircleColorCircle),
      );
    }
  }

  Future<void> _saveImage(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    late String message;

    try {
      // Download image
      final http.Response response = await http.get(Uri.parse(imageUrl!));

      // Get temporary directory
      final dir = await getTemporaryDirectory();

      // Create an image name
      var filename = '${dir.path}/SaveImage${random.nextInt(1000)}.png';

      // Save to filesystem
      final file = File(filename);
      await file.writeAsBytes(response.bodyBytes);

      // Ask the user to save it
      final params = SaveFileDialogParams(sourceFilePath: file.path);
      final finalPath = await FlutterFileDialog.saveFile(params: params);

      if (finalPath != null) {
        message = 'Image saved to disk';
      }
    } catch (e) {
      message = e.toString();
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
          message,
          style:const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:const Color(0xFFe91e63),
      ));
    }

    if (message != null) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
          message,
          style:const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:const Color(0xFFe91e63),
      ));
    }
  }
}
