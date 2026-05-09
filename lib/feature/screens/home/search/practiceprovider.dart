// ignore_for_file: avoid_print, unused_local_variable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Practiceprovider extends ChangeNotifier {
  List user = [];
  Future<void> getResult(String name, String number) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.12:3000/users'),
      headers: ({"Content-Type": "application/json"}),
      body: jsonEncode({'name': name, 'phoneNumber': number}),
    );
    if (response.statusCode == 200) {
      print('User Added SuccesFully');
      user.add({'name': name, 'PhoneNumber': response});
      notifyListeners();
      print(response.body);
    } else {
      print("Error: ${response.statusCode}");
    }
  }
}
