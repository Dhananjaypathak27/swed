import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swed/screen/home_page.dart';
import 'package:swed/util/Authentication.dart';
import 'package:swed/util/shared_pref.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  _GoogleSignInButtonState createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;
  SharedPref sharedPref = SharedPref();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return _isSigningIn
        ? const CircularProgressIndicator(
      color: Colors.white,
    )
        : OutlinedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.white),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            onPressed: () async {

              final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

              if (connectivityResult.contains(ConnectivityResult.none)) {
                // No available network types
                ScaffoldMessenger.of(context).showSnackBar( const SnackBar(
                  content: Text(
                    "No Internet connection available!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Color(0xFFe91e63),
                ));
              }
              else{
                setState(() {
                  _isSigningIn = true;
                });
                User? user =
                await Authentication.signInWithGoogle(context: context);

                setState(() {
                  _isSigningIn = false;
                });

                if (user != null) {
                  sharedPref.addBoolToPref("userLoggedIn",true);
                  sharedPref.addStringToPref("photoUrl", user.photoURL??"");
                  sharedPref.addStringToPref("userName", user.displayName??"user");

                  print("user name ${user.displayName} photoUrl ${user.photoURL}");
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) =>  const Homepage()
                    ),
                  );
                }
              }



            },
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image(image: AssetImage('assets/images/google_logo.png'),height: 35,),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
  }
}
