import 'package:chatloop/feature/screens/home/search/practiceprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Practice extends StatefulWidget {
  const Practice({super.key});

  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> {
  TextEditingController name = TextEditingController();
  TextEditingController phoneNumber = TextEditingController();
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Practiceprovider>(
      create: (context) => Practiceprovider(),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(),
          body: Consumer<Practiceprovider>(
            builder: (context, providerPractice, child) {
              return Column(
                children: [
                  TextFormField(controller: name),
                  TextFormField(controller: phoneNumber),
                  ElevatedButton(
                    onPressed: () {
                      providerPractice.getResult(name.text, phoneNumber.text);
                    },
                    child: const Text('post'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
