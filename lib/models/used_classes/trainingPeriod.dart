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

import 'dart:convert';

import 'package:githo/extracted_data/dataShortcut.dart';
import 'package:githo/helpers/timeHelper.dart';
import 'package:githo/models/habitPlanModel.dart';
import 'package:githo/models/used_classes/training.dart';

class TrainingPeriod {
  late int index;
  late int number;
  late int durationInHours;
  late String durationText;
  late int requiredTrainings;
  String status = "";
  late List<Training> trainings;

  TrainingPeriod.fromHabitPlan({
    required int trainingPeriodIndex,
    required HabitPlan habitPlan,
  }) {
    this.index = trainingPeriodIndex;
    this.number = trainingPeriodIndex + 1;

    // Calculate the duration
    final int trainingTimeIndex = habitPlan.trainingTimeIndex;
    this.durationInHours =
        DataShortcut.periodDurationInHours[trainingTimeIndex];
    this.durationText = DataShortcut.timeFrames[trainingTimeIndex + 1];

    // Get required trainings
    this.requiredTrainings = habitPlan.requiredTrainings;

    // Create all the TrainingPeriod-instances
    final int trainingCount = DataShortcut.maxTrainings[trainingTimeIndex];
    this.trainings = [];
    for (int i = 0; i < trainingCount; i++) {
      final int trainingIndex = trainingPeriodIndex * trainingCount + i;
      this.trainings.add(
            Training.fromHabitPlan(
              trainingIndex: trainingIndex,
              habitPlan: habitPlan,
            ),
          );
    }
  }

  TrainingPeriod({
    required this.index,
    required this.number,
    required this.durationInHours,
    required this.durationText,
    required this.requiredTrainings,
    required this.status,
    required this.trainings,
  });

  void setChildrenDates(DateTime startingDate) {
    for (final Training training in this.trainings) {
      training.setDates(startingDate);
      startingDate =
          startingDate.add(Duration(hours: training.durationInHours));
    }
  }

  Map<String, dynamic>? getDataByDate(DateTime date) {
    Map<String, dynamic>? result;

    for (final Training training in this.trainings) {
      if ((training.startingDate.isAtSameMomentAs(date) ||
              training.startingDate.isBefore(date)) &&
          training.endingDate.isAfter(date)) {
        result = Map<String, dynamic>();
        result["training"] = training;
        result["trainingPeriod"] = this;
        break;
      }
    }
    return result;
  }

  void activate() {
    this.status = "active";
    this.trainings[0].status = "current";
  }

  void reset() {
    // Reset self
    this.status = "";

    // Reset trainings
    for (final Training training in this.trainings) {
      training.reset();
    }
  }

  void resetTrainingProgresses(int startingNumber) {
    for (final Training training in this.trainings) {
      if (training.number >= startingNumber) {
        training.status = "";
        training.doneReps = 0;
      }
    }
  }

  Map<String, dynamic>? getActiveData() {
    Map<String, dynamic>? result;

    for (final Training training in this.trainings) {
      if (training.status == "current" ||
          training.status == "active" ||
          training.status == "done") {
        result = Map<String, dynamic>();
        result["training"] = training;
        result["trainingPeriod"] = this;
        break;
      }
    }
    return result;
  }

  bool get wasSuccessful {
    final bool result;
    int successfulTrainings = 0;

    for (final Training training in this.trainings) {
      if (training.status == "successful") {
        successfulTrainings++;
      }
    }
    result = (successfulTrainings >= requiredTrainings);
    return result;
  }

  int get successfulTrainings {
    // This also counts the current day!!
    int successfulTrainings = 0;

    for (final Training training in this.trainings) {
      if (training.status == "successful" || training.status == "done") {
        successfulTrainings++;
      }
    }
    return successfulTrainings;
  }

  int get remainingTrainings {
    // Count how many trainings come after the current one
    int remainingTrainings = 0;
    for (final Training training in this.trainings) {
      final DateTime now = TimeHelper.instance.currentTime;
      if (training.endingDate.isAfter(now)) {
        remainingTrainings++;
      }
    }
    return remainingTrainings;
  }

  void setResult() {
    this.status = "completed";
  }

  void markIfPassed() {
    final Training lastTraining = this.trainings.last;
    final DateTime now = TimeHelper.instance.currentTime;
    if (lastTraining.endingDate.isBefore(now)) {
      setResult();
    }
  }

  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> trainingMapList = [];

    for (final Training training in this.trainings) {
      trainingMapList.add(training.toMap());
    }

    final Map<String, dynamic> map = {};
    map["index"] = this.index;
    map["number"] = this.number;
    map["durationInHours"] = this.durationInHours;
    map["durationText"] = this.durationText;
    map["requiredTrainings"] = this.requiredTrainings;
    map["status"] = this.status;
    map["trainings"] = jsonEncode(trainingMapList);
    return map;
  }

  factory TrainingPeriod.fromMap(final Map<String, dynamic> map) {
    List<Training> jsonToList(final String json) {
      final List<dynamic> dynamicList = jsonDecode(json);
      final List<Training> trainings = [];

      for (final dynamic trainingMap in dynamicList) {
        trainings.add(Training.fromMap(trainingMap));
      }

      return trainings;
    }

    return TrainingPeriod(
      index: map["index"],
      number: map["number"],
      durationInHours: map["durationInHours"],
      durationText: map["durationText"],
      requiredTrainings: map["requiredTrainings"],
      status: map["status"],
      trainings: jsonToList(map["trainings"]),
    );
  }
}
