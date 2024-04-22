import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:swed/services/open_ai_service.dart';
import 'package:swed/util/Authentication.dart';
import 'package:swed/util/pallete.dart';
import 'package:swed/screen/chat_gpt_screen.dart';
import 'package:swed/screen/dall_e_screen.dart';
import 'package:swed/screen/login_screen.dart';
import 'package:swed/util/internet_connectivity.dart';
import 'package:swed/util/shared_pref.dart';

import '../widgets/feature_box.dart';
import 'package:http/http.dart' as http;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final sharedPref = SharedPref();
  OpenAIService openAIService = OpenAIService();

  final speechToText = SpeechToText();
  String lastWords = "";
  bool _validate = false;
  bool showProgressBar = false;
  String userName = "";
  String newValue = "";
  String firebaseSecretKey = "";
  String errorMessage= "";
  String passcodeCurrentText = "";
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initTextToSpeech();
    getUserDetails();
    initFireStore();
    textEditingController.addListener(getTextFromTextField);
  }

  void getTextFromTextField() {
    if(textEditingController.text == passcodeCurrentText){

    }
    else{
      setState(() {
        errorMessage = "";
        _validate = false;
      });
    }
  }

  initFireStore() async {
   WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    var document = await FirebaseFirestore.instance
        .collection('sward_collection')
        .doc('onuv5xmULbD9ZS5vLmU9')
        .get();
    Map<String, dynamic>? value = document.data();
    print(value!['secret_key']);
    String key = await sharedPref.getStringFromPref("secret_key");
    print("value from fire base ${value!['secret_key']}  shared pref $key");
    firebaseSecretKey = value!['secret_key'];
    if (key == value!['secret_key']) {
      print("is same");
    } else {
      print("is not same");
      showAccessRemoveDialog();
    }
  }

  void showAccessRemoveDialog() {
    showDialog<String>(
        barrierDismissible: false,
        context: context,
        builder: (_) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text("Access Removed"),
              content: const Text(
                  "Enter pass-code to use this application"),
              actions: <Widget>[
                TextButton(
                  child: const Text("Enter pass-code",style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showPassCodeDialog();
                  },
                ),
                TextButton(
                  child: const Text("Log Out",style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showLogoutDialog();

                  },
                ),
              ],
            )));
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

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {
      showProgressBar = true;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      print(result.recognizedWords);
      if (result.finalResult) {
        lastWords = result.recognizedWords;
        print("final word " + lastWords);
        if (lastWords.isNotEmpty) {
          isArtPromptApiCall();
        }
      }
    });
  }

  void isArtPromptApiCall() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    InternetConnectivity connectivity = InternetConnectivity();
    if (await connectivity.checkInternetConnection()) {
      try {
        http.Response res = await openAIService.isArtPromptAPI2(lastWords);
        if (res.statusCode == 200) {
          print("yehh" + res.body);
          String content =
              jsonDecode(res.body)["choices"][0]['message']['content'];
          content = content.trim();
          print("content $content");

          switch (content) {
            case 'yes':
            case 'Yes':
            case 'yes.':
            case 'Yes.':
            case 'YES':
            case 'YES.':
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => DallEScreen(prompt: lastWords)),
              );

            default:
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => ChatGPTScreen(prompt: lastWords)),
              );
          }
        }
      } catch (e) {
        String errorMessage = "Error occurred - ${e.toString()}";
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(
            errorMessage,
            style:const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFFe91e63),
        ));
      }
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(
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

    setState(() {
      showProgressBar = false;
    });
  }

  void moveToDallEOrChatGPT(bool isImage) {
    if (isImage) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => DallEScreen(
                  prompt: lastWords,
                )),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => ChatGPTScreen(
                  prompt: lastWords,
                )),
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    speechToText.stop();
  }

  showPassCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pass-code",style: TextStyle(fontWeight: FontWeight.bold),),
          content: const Text(
              "Enter pass-code provided by Admin"),
          actions: [Row(
        mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                maxLines: 1,
                minLines: 1,
                controller: textEditingController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                  hintText: 'Enter a pass-code',
                    errorText: _validate ? errorMessage : null,
                  hintStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w300),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),

              ),
            ),
            Container(
                margin:const EdgeInsets.only(left: 5),
                child: IconButton(
                  padding:const EdgeInsets.all(12),
                  onPressed: () async {
                    if(textEditingController.text.isNotEmpty){
                      // scrollToBottom();
                      FocusScope.of(context).unfocus();
                      //check data is matching or not
                      if(textEditingController.text.toString()==firebaseSecretKey){
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        Navigator.pop(context);
                        sharedPref.addStringToPref("secret_key",firebaseSecretKey );
                      }
                      else{
                        FocusScope.of(context).unfocus();
                        setState(() {
                          passcodeCurrentText = textEditingController.text.toString();
                          _validate = true;
                          errorMessage = "Please Enter A valid pass-code";
                        });
                      }
                    }
                    else{
                      FocusScope.of(context).unfocus();
                      setState(() {
                        passcodeCurrentText = textEditingController.text.toString();
                        _validate = true;
                        errorMessage = "Please Enter A pass-code";
                      });
                    }
                  },
                  icon: const Icon(Icons.send, size: 26, color: Colors.white),
                  style: IconButton.styleFrom(
                      shape: const CircleBorder(), backgroundColor: Pallete.assistantCircleColorCircle),
                )),
          ],
        ),
          ],
        );
      },
    );
  }

  showLogoutDialog() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Log Out',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text('Are you sure you want to log out?'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Pallete.mainFontColor),
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        logoutUser();
                      },
                      child:const Text("Log Out",
                          style: TextStyle(color: Pallete.mainFontColor)))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Swed"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            showLogoutDialog();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //virtual assistant picture
            FadeInDown(
              duration:const Duration(seconds: 1),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      height: 120,
                      width: 120,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                          color: Pallete.assistantCircleColorCircle,
                          shape: BoxShape.circle),
                    ),
                  ),
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/ai_image.png'))),
                  ),
                ],
              ),
            ),
            //chat bubble
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              margin:
                  const EdgeInsets.symmetric(horizontal: 40).copyWith(top: 30),
              decoration: BoxDecoration(
                  border: Border.all(color: Pallete.borderColor),
                  borderRadius:
                      BorderRadius.circular(10).copyWith(topLeft: Radius.zero)),
              child: Padding(
                padding:const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Hi ${userName.toUpperCase()}, Welcome to Sward, You Personalized AI Assistant',
                  style:const TextStyle(
                      color: Pallete.mainFontColor,
                      fontSize: 16,
                      fontFamily: 'Cera Pro'),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 10, left: 22),
              child: const Text(
                "Features",
                style: TextStyle(
                  fontFamily: "Cera Pro",
                  color: Pallete.mainFontColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              children: [
                FadeInLeft(
                  duration:const Duration(milliseconds: 800),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ChatGPTScreen()),
                      );
                    },
                    child: const FeatureBox(
                      color: Pallete.firstSuggestionBoxColor,
                      descriptionText:
                          "Connect, Learn, and Explore with AI Chat: Where Conversations Shape Tomorrow.",
                      headerText: "Chat-Bot",
                    ),
                  ),
                ),
                FadeInLeft(
                  duration:const Duration(milliseconds: 1000),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => DallEScreen()),
                      );
                    },
                    child: const FeatureBox(
                      color: Pallete.secondSuggestionBoxColor,
                      descriptionText:
                          "Unlock Creativity Beyond Imagination: AI Image Generator, Where Every Pixel Sparks Inspiration.",
                      headerText: "Image Generator",
                    ),
                  ),
                ),
                FadeInLeft(
                  duration:const Duration(milliseconds: 1200),
                  child: InkWell(
                    onTap: () {
                      smartAssistantButtonClicked();
                    },
                    child: const FeatureBox(
                      color: Pallete.thirdSuggestionBoxColor,
                      descriptionText:
                          "Get the best of both worlds with a voice assistance powered",
                      headerText: "Smart Voice Assistant",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Pallete.assistantCircleColor,
        onPressed: () async {
          smartAssistantButtonClicked();
        },
        child: Icon(speechToText.isListening ? Icons.stop : Icons.mic),
      ),
    );
  }

  void smartAssistantButtonClicked() async {
    lastWords = "";
    if (await speechToText.hasPermission && speechToText.isNotListening) {
      _startListening();
    } else if (speechToText.isListening) {
      if (lastWords.isNotEmpty) {
        isArtPromptApiCall();
      }
      stopListening();
    } else {
      initTextToSpeech();
    }
  }

  getUserDetails() async {
    var temp = await sharedPref.getStringFromPref("userName");
    setState(() {
      userName = temp ?? "user";
    });
  }

  void logoutUser() async {
    Navigator.pop(context);
    await sharedPref.clearPref();
    await Authentication.signOut(context: context);
    setState(() {});
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (_) => false);
  }
}
