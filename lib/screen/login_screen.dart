import 'package:animate_do/animate_do.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:swed/util/pallete.dart';
import 'package:swed/widgets/google_sign_in_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../util/Authentication.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.assistantCircleColorCircle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FadeInDown(
            duration: const Duration(seconds: 2),
            child:const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SWARD,",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 50,color: Colors.white,fontFamily: 'Cera Pro')),
                Text("You Personalized AI Assistant",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.white,fontFamily: 'Cera Pro'),),
              ],
            ),
          ),
          const SizedBox(height:30),
            FadeInLeft(
            duration:const Duration(seconds: 1),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: MediaQuery.sizeOf(context).height/5,

                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                        color: Pallete.assistantCircleColorCircle,
                        shape: BoxShape.circle),
                  ),
                ),
                Container(
                  height: MediaQuery.sizeOf(context).height/4,
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              'assets/images/ai_image.png'))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50,),
          FutureBuilder(
            future: Authentication.initializeFirebase(context: context),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('Error initializing Application, Retry after sometime',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),);

              } else if (snapshot.connectionState == ConnectionState.done) {
                return const GoogleSignInButton();
              }
              else if (snapshot.connectionState == ConnectionState.none){
                return const Text('No connection available at the moment, try after sometime',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),);

              }
              return const CircularProgressIndicator(
                color: Colors.white,
              );
            },
          ),
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Linkify(
          onOpen: (link) async {
            if (!await launchUrl(Uri.parse("https://www.xparticle.in/termsAndConditions.html"))) {
              throw Exception('Could not launch ${link.url}');
            }
          },
          text: "By logging in, you accept our https://terms-And-Conditions and https://Privacy-Policy",
          style:const TextStyle(color: Colors.white),
          linkStyle:const TextStyle(color: Colors.red),
        ),
      )
        ],
      ),
    );
  }
}
