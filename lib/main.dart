import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_data/sim_data.dart';
import 'package:ussd_service/ussd_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum RequestState {
  Ongoing,
  Success,
  Error,
}

class _MyAppState extends State<MyApp> {
  RequestState _requestState;
  String _requestCode = "";
  String _responseCode = "";
  String _responseMessage = "";

  Future<void> sendUssdRequest() async {
    setState(() {
      _requestState = RequestState.Ongoing;
    });
    try {
      String responseMessage;
      await Permission.phone.request();
      if (!await Permission.phone.isGranted) {
        throw Exception("permission requise");
      }

      SimData simData = await SimDataPlugin.getSimData();
      if (simData == null) {
        throw Exception("les données sim sont nulles");
      }
      responseMessage = await UssdService.makeRequest(
          simData.cards.first.subscriptionId, _requestCode);
      setState(() {
        _requestState = RequestState.Success;
        _responseMessage = responseMessage;
      });
    } catch (e) {
      setState(() {
        _requestState = RequestState.Error;
        _responseCode = e is PlatformException ? e.code : "";
        _responseMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ussd App'),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Entrer le Code',
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      _requestCode = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),
                MaterialButton(
                  color: Colors.indigo,
                  textColor: Colors.white,
                  onPressed: _requestState == RequestState.Ongoing
                      ? null
                      : () {
                          sendUssdRequest();
                        },
                  child: const Text('Requete Ussd envoyée'),
                ),
                const SizedBox(height: 20),
                if (_requestState == RequestState.Ongoing)
                  Row(
                    children: const <Widget>[
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(width: 24),
                      Text('Requete en cours...'),
                    ],
                  ),
                if (_requestState == RequestState.Success) ...[
                  const Text('Derniére requete effectuée avec Succès.'),
                  const SizedBox(height: 10),
                  const Text('La reponse:'),
                  Text(
                    _responseMessage,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                if (_requestState == RequestState.Error) ...[
                  const Text('Derniére requete effectuée avec Succès.'),
                  const SizedBox(height: 10),
                  const Text("Message d'erreur:"),
                  Text(
                    _responseCode,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text("La reponse:"),
                  Text(
                    _responseMessage,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ]
              ]),
        ),
      ),
    );
  }
}
