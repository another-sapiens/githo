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

import 'package:githo/config/data_shortcut.dart';
import 'package:githo/helpers/time_helper.dart';
import 'package:githo/models/habit_plan.dart';
import 'package:githo/models/used_classes/training.dart';

/// A group of [Training]s.
///
/// One or multiple [TrainingPeriods] can make up a step ([StepData]).
///
/// Example: For daily habits this would be a week.

class TrainingPeriod {
  /// Creates a [TrainingPeriod] by directly supplying its values.
  TrainingPeriod({
    required this.index,
    required this.number,
    required this.durationInHours,
    required this.durationText,
    required this.requiredTrainings,
    required this.status,
    required this.trainings,
  });

  /// Creates a [TrainingPeriod] from a [HabitPlan].
  TrainingPeriod.fromHabitPlan({
    required final int trainingPeriodIndex,
    required final HabitPlan habitPlan,
  })  : index = trainingPeriodIndex,
        number = trainingPeriodIndex + 1,
        durationInHours =
            DataShortcut.periodDurationInHours[habitPlan.trainingTimeIndex],
        durationText = DataShortcut.timeFrames[habitPlan.trainingTimeIndex],
        requiredTrainings = habitPlan.requiredTrainings,
        // Create all the TrainingPeriod-instances
        trainings = _getTrainings(trainingPeriodIndex, habitPlan);

  /// Converts a Map into a [TrainingPeriod].
  TrainingPeriod.fromMap(final Map<String, dynamic> map)
      : index = map['index'] as int,
        number = map['number'] as int,
        durationInHours = map['durationInHours'] as int,
        durationText = map['durationText'] as String,
        requiredTrainings = map['requiredTrainings'] as int,
        status = map['status'] as String,
        trainings = _jsonToTrainingList(map['trainings'] as String);

  final int index;
  final int number;
  final int durationInHours;
  final String durationText;

  /// The number of [Training]s that are required to successfully complete
  /// this [TrainingPeriod].
  final int requiredTrainings;
  String status = '';
  final List<Training> trainings;

  /// Generates and returns the [List] of [Training]s that
  /// form this [TrainingPeriod].
  static List<Training> _getTrainings(
    final int trainingPeriodIndex,
    final HabitPlan habitPlan,
  ) {
    final List<Training> trainings = <Training>[];
    final int trainingTimeIndex = habitPlan.trainingTimeIndex;
    final int trainingCount = DataShortcut.maxTrainings[trainingTimeIndex];

    for (int i = 0; i < trainingCount; i++) {
      final int trainingIndex = trainingPeriodIndex * trainingCount + i;
      trainings.add(
        Training.fromHabitPlan(
          trainingIndex: trainingIndex,
          habitPlan: habitPlan,
        ),
      );
    }
    return trainings;
  }

  /// Converts a [json]-like [String] into a list of [Training]s.
  static List<Training> _jsonToTrainingList(final String json) {
    final dynamic dynamicList = jsonDecode(json);
    final List<Training> trainings = <Training>[];

    for (final Map<String, dynamic> map in dynamicList) {
      final Training training = Training.fromMap(map);
      trainings.add(training);
    }
    return trainings;
  }

  /// Sets the dates of its [Training]-children.
  ///
  /// The first [training] starts at [startingDate].
  void setChildrenDates(final DateTime startingDate) {
    DateTime currentStartingDate = startingDate;

    for (final Training training in trainings) {
      training.setDates(currentStartingDate);
      currentStartingDate =
          currentStartingDate.add(Duration(hours: training.durationInHours));
    }
  }

  /// Returns [this] and the [training]-child
  /// if a [training] is found that is active  at [date].
  Map<String, dynamic>? getDataByDate(final DateTime date) {
    for (final Training training in trainings) {
      if ((training.startingDate.isAtSameMomentAs(date) ||
              training.startingDate.isBefore(date)) &&
          training.endingDate.isAfter(date)) {
        final Map<String, dynamic> result = <String, dynamic>{
          'training': training,
          'trainingPeriod': this,
        };
        return result;
      }
    }
  }

  /// Only used **ONCE**: The first time when the waiting-for-start-period needs
  /// to become active for progressData._analyzePassedTime(); to not crash.
  void initialActivation() {
    status = 'active';
    trainings[0].status = 'ready';
  }

  /// Reset [this.status] and all its [training]-children.
  void reset() {
    // Reset self
    status = '';

    // Reset trainings
    for (final Training training in trainings) {
      training.reset();
    }
  }

  /// Reset the [training]-children that come after a certain training-number.
  void resetProgressAfterNr(final int startingNumber) {
    for (final Training training in trainings) {
      if (training.number >= startingNumber) {
        training.reset();
      }
    }
  }

  /// Returns [this] and the [training]-child if a [training] in [this] has a status indicating that it is current/active.
  Map<String, dynamic>? get activeData {
    for (final Training training in trainings) {
      if (training.isActive) {
        final Map<String, dynamic> result = <String, dynamic>{
          'training': training,
          'trainingPeriod': this,
        };
        return result;
      }
    }
  }

  /// Checks if enough [trainings] were successful for [this] to be successful.
  bool get wasSuccessful {
    int successfulTrainings = 0;

    for (final Training training in trainings) {
      if (training.status == 'successful') {
        successfulTrainings++;
      }
    }
    final bool wasSuccessful = successfulTrainings >= requiredTrainings;
    return wasSuccessful;
  }

  /// Returns how many [trainings] so far were successful
  /// within this [TrainingPeriod].
  ///
  /// This includes the current day in it's calculation.
  int get successfulTrainings {
    int successfulTrainings = 0;

    for (final Training training in trainings) {
      if (training.status == 'successful' || training.status == 'done') {
        successfulTrainings++;
      }
    }
    return successfulTrainings;
  }

  /// Counts how many trainings come after the current one.
  int get remainingTrainings {
    int remainingTrainings = 0;
    for (final Training training in trainings) {
      final DateTime now = TimeHelper.instance.currentTime;
      if (training.endingDate.isAfter(now)) {
        remainingTrainings++;
      }
    }
    return remainingTrainings;
  }

  /// Sets the [status] of [this] to 'completed'.
  void setResult() {
    status = 'completed';
  }

  /// Checks if the [TrainingPeriod] is over. If so, it is marked accordingly.
  void markIfPassed() {
    final Training lastTraining = trainings.last;
    final DateTime now = TimeHelper.instance.currentTime;
    if (lastTraining.endingDate.isBefore(now)) {
      setResult();
    }
  }

  /// Converts the [TrainingPeriod] into a Map.
  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> trainingMapList = <Map<String, dynamic>>[];

    for (final Training training in trainings) {
      trainingMapList.add(training.toMap());
    }

    final Map<String, dynamic> map = <String, dynamic>{
      'index': index,
      'number': number,
      'durationInHours': durationInHours,
      'durationText': durationText,
      'requiredTrainings': requiredTrainings,
      'status': status,
      'trainings': jsonEncode(trainingMapList),
    };
    return map;
  }
}
