/* 
 * Githo – An app that helps you form long-lasting habits, one step at a time.
 * Copyright (C) 2021 Florian Thaler
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:githo/config/style_data.dart';
import 'package:githo/models/used_classes/training.dart';

class ConfirmTrainingStart extends StatelessWidget {
  /// Returns a dialog that lets the user confirm that he really
  /// wants to start the current training.
  const ConfirmTrainingStart({
    required this.title,
    required this.toDo,
    required this.training,
    required this.onConfirmation,
  });

  final String title;
  final String toDo;
  final Training training;
  final Function onConfirmation;

  @override
  Widget build(BuildContext context) {
    final String amountString;
    if (training.requiredReps == 1) {
      amountString = 'Perform once';
    } else {
      amountString = 'Perform ${training.requiredReps} times';
    }

    return AlertDialog(
      title: const Text(
        'Tackle the next training?',
        style: StyleData.textStyle,
      ),
      content: Text(
        'To-Do: $toDo\n\nReps: $amountString',
        style: StyleData.textStyle,
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <ElevatedButton>[
            ElevatedButton.icon(
              icon: const Icon(
                Icons.cancel,
                color: Colors.white,
              ),
              label: const Text(
                'Cancel',
                style: StyleData.whiteTextStyle,
              ),
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.orange),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              label: const Text(
                'Start',
                style: StyleData.whiteTextStyle,
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirmation();
              },
            ),
          ],
        ),
      ],
    );
  }
}
