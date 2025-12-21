import 'package:flutter/material.dart';
import 'package:valyuta_cevirici/ana_sehife.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async{
  await dotenv.load(fileName: "dotenv.env");
  runApp(Program());
}

class Program extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AnaSehife(),
    );
  }
}
