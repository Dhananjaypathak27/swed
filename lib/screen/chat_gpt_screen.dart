import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:swed/services/open_ai_service.dart';
import 'package:swed/util/pallete.dart';
import 'package:swed/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:swed/util/internet_connectivity.dart';
import 'package:swed/util/shared_pref.dart';

class ChatGPTScreen extends StatefulWidget {
  String? prompt;

  ChatGPTScreen({super.key, this.prompt});

  @override
  State<ChatGPTScreen> createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGPTScreen> {
  final speechToText = SpeechToText();
  final sharedPref = SharedPref();
  TextEditingController textEditingController = TextEditingController();
  OpenAIService openAIService = OpenAIService();
  bool isUserTyping = false;
  bool showProgressBar = false;
  String userName = "";
  List<UserModel> listsData = [];
  ScrollController listScrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initDetails();
  }

  initDetails() async {
    await getUserDetails();
    textEditingController.addListener(getTextFromTextField);
    initSpeechToText();
    if (widget.prompt != null && widget.prompt!.isNotEmpty) {
      listsData.add(UserModel(content: widget.prompt, role: "user"));
      submitResult(listsData);
    } else {
      listsData.add(UserModel(
          content: "Hello $userName! How can I assist you today?",
          role: "assistant"));
      setState(() {});
    }
  }

  getUserDetails() async {
    var temp = await sharedPref.getStringFromPref("userName");
    setState(() {
      userName = temp ?? "user";
    });
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await speechToText.listen(
        onResult: _onSpeechResult, listenFor: Duration(minutes: 1));
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    print(result.recognizedWords);
    InternetConnectivity connectivity = InternetConnectivity();
    if (result.finalResult) {
      if (await connectivity.checkInternetConnection()) {
        if (result.recognizedWords.isNotEmpty) {
          listsData
              .add(UserModel(role: "user", content: result.recognizedWords));
          print("final word ${result.recognizedWords}");
          submitResult(listsData);
        }
      } else {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
    setState(() {});
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

  void submitResult(List<UserModel> list) async {
    textEditingController.text = "";
    setState(() {
      showProgressBar = true;
    });
    try {
      http.Response res = await openAIService.chatGPTAPI(list);
      print(res.body);
      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)["choices"][0]['message']['content'];
        content = content.trim();
        listsData
            .add(UserModel.fromJson({"role": "assistant", "content": content}));

        setState(() {
          // Get the full content height.
          final contentSize = listScrollController.position.viewportDimension +
              listScrollController.position.maxScrollExtent;
          // Index to scroll to.
          final index = listsData.length - 1;
          // Estimate the target scroll position.
          final target = contentSize * index / listsData.length;
          listScrollController.position.animateTo(target,
              duration:const Duration(microseconds: 200), curve: Curves.easeIn);
        });
      } else {
        widget.prompt = null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error Occurred ${res.body}"),
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
    });
  }

  void scrollToBottom() async {
    double position = listScrollController.position.maxScrollExtent;
    Future.delayed(const Duration(microseconds: 100), () {
      setState(() {
        listScrollController.jumpTo(position);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Chat-Bot'),
      ),
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: Container(
          color: Colors.transparent,
          margin:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5)
              .copyWith(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  minLines: 1,
                  controller: textEditingController,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    hintText: 'Enter a Prompt',
                    hintStyle: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w300),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ),
              Container(
                  margin: const EdgeInsets.only(left: 5),
                  child: showSendOrRecordingButton()),
            ],
          )),
      body: Stack(children: [
        ListView.builder(
          controller: listScrollController,
          itemCount: listsData.length,
          itemBuilder: (context, index) {
            return showGPTorSenderCard(listsData[index]);
          },
        ),
        Visibility(
          visible: showProgressBar,
          child: Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: JumpingDots(
                color: Pallete.assistantCircleColorCircle,
                radius: 15,
              )),
        ),
      ]),
    );
  }

  Widget showGPTorSenderCard(UserModel data) {
    if (data.role == "assistant") {
      return GPTCardListItem(data: data);
    } else {
      return SenderCardListItem(data: data);
    }
  }

  Widget showSendOrRecordingButton() {
    if (isUserTyping) {
      return IconButton(
        padding: EdgeInsets.all(12),
        onPressed: () async {
          InternetConnectivity connectivity = InternetConnectivity();
          if (await connectivity.checkInternetConnection()) {
            if (textEditingController.text.isNotEmpty) {
              // scrollToBottom();
              FocusScope.of(context).unfocus();
              listsData.add(UserModel.fromJson(
                  {"role": "user", "content": textEditingController.text}));
              submitResult(listsData);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please Enter A Prompt"),
              ));
            }
          } else {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "No internet connection available",
              ),
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
        padding: const EdgeInsets.all(12),
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
        padding: const EdgeInsets.all(12),
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
}

class SenderCardListItem extends StatefulWidget {
  final UserModel data;

  const SenderCardListItem({super.key, required this.data});

  @override
  State<SenderCardListItem> createState() => _SenderCardListItemState();
}

class _SenderCardListItemState extends State<SenderCardListItem> {
  FlutterTts flutterTts = FlutterTts();

  Future speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 50),
      child: Card(
        color: Pallete.assistantCircleColorCircle,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20))
              .copyWith(bottomRight: Radius.zero),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.data.content}",
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                        onTap: () {
                          speak(widget.data.content!);
                        },
                        child: const Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        )),
                    const SizedBox(
                      width: 20,
                    ),
                    InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: "${widget.data.content}"));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("copied to clipboard"),
                          ));
                        },
                        child: const Icon(Icons.copy, color: Colors.white))
                  ],
                )
              ],
            )),
      ),
    );
  }
}

class GPTCardListItem extends StatefulWidget {
  final UserModel data;

  const GPTCardListItem({super.key, required this.data});

  @override
  State<GPTCardListItem> createState() => _GPTCardListItemState();
}

class _GPTCardListItemState extends State<GPTCardListItem> {
  FlutterTts flutterTts = FlutterTts();

  Future speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 50),
      child: Card(
        color: Colors.grey[300],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20))
              .copyWith(bottomLeft: Radius.zero),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Column(
              children: [
                Text("${widget.data.content}"),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                        onTap: () {
                          speak(widget.data.content!);
                        },
                        child: const Icon(Icons.volume_up)),
                    const SizedBox(
                      width: 20,
                    ),
                    InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: "${widget.data.content}"));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text("copied to clipboard"),
                          ));
                        },
                        child: const Icon(Icons.copy))
                  ],
                )
              ],
            )),
      ),
    );
  }
}
