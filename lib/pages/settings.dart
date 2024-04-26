import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kennzeichen/database/model.dart';
import 'package:kennzeichen/database/model/kennzeichen.dart';

class PageSettings extends StatelessWidget {

  const PageSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text("Einstellungen"),
        centerTitle: Platform.isIOS,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            FutureBuilder(
              future: Model.count(Kennzeichen()),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final count = snapshot.data ?? 0;
                  return Text("Die Datenbank enthält z.Z. $count deutsche KFZ-Kennzeichen.",
                    textAlign: TextAlign.center);
                }

                return const LinearProgressIndicator();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

}