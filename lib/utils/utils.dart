import 'package:flutter/material.dart';

nextScreen(BuildContext context, Widget screen) {
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: ((context) => screen)));
}

nextScreenNoReplace(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: ((context) => screen)));
}
