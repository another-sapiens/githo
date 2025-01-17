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

import 'package:githo/helpers/type_extentions.dart';
import 'package:githo/helpers/time_helper.dart';
import 'package:githo/database/database_helper.dart';
import 'package:githo/models/habit_plan.dart';
import 'package:githo/models/used_classes/step.dart';
import 'package:githo/models/used_classes/training.dart';
import 'package:githo/models/used_classes/training_period.dart';

/// The model for how progress is structured and tracked.

class ProgressData {
  ProgressData({
    required this.habitPlanId,
    required this.isActive,
    required this.fullyCompleted,
    required this.currentStartingDate,
    required this.habit,
    required this.steps,
  });

  /// Creates dummy, inactive [ProgressData].
  ProgressData.emptyData()
      : habitPlanId = 123456789,
        isActive = false,
        fullyCompleted = false,
        currentStartingDate = DateTime(0),
        habit = '',
        steps = const <StepData>[];

  /// Converts a Map into [ProgressData].
  ProgressData.fromMap(final Map<String, dynamic> map)
      : habitPlanId = map['habitPlanId'] as int,
        isActive = (map['isActive'] as int).toBool(),
        fullyCompleted = (map['fullyCompleted'] as int).toBool(),
        currentStartingDate =
            DateTime.parse(map['currentStartingDate'] as String),
        habit = map['goal'] as String,
        steps = _jsonToStepList(map['steps'] as String);

  int habitPlanId;
  bool isActive;
  bool fullyCompleted;
  DateTime currentStartingDate;
  String habit;
  List<StepData> steps;

  /// Converts a [json]-like [String] into a list of [StepData].
  static List<StepData> _jsonToStepList(final String json) {
    final dynamic dynamicList = jsonDecode(json);
    final List<StepData> steps = <StepData>[];

    for (final Map<String, dynamic> map in dynamicList) {
      final StepData step = StepData.fromMap(map);
      steps.add(step);
    }

    return steps;
  }

  /// Adapts [this] to a HabitPlan.
  void adaptToHabitPlan({
    required final HabitPlan habitPlan,
    required final DateTime startingDate,
    final int startingStepNr = 1,
  }) {
    habitPlanId = habitPlan.id!;
    isActive = true;
    fullyCompleted = habitPlan.fullyCompleted;
    currentStartingDate = startingDate;
    habit = habitPlan.habit;
    steps = <StepData>[];
    for (int i = 0; i < habitPlan.steps.length; i++) {
      steps.add(
        StepData.fromHabitPlan(
          stepIndex: i,
          habitPlan: habitPlan,
        ),
      );
    }

    final int startingStepIdx = startingStepNr - 1;
    steps[startingStepIdx].trainingPeriods[0].status = 'waiting for start';

    final Map<String, int> startingIdxData = <String, int>{
      'step': startingStepIdx,
      'trainingPeriod': 0,
    };
    _setTrainingDates(startingIdxData);

    if (startingStepNr > 0) {
      // Set the passed trainings' status to 'completed'
      _completePassedPeriods();
    }
  }

  // Regularly used functions

  /// Checks whether [this] has started or if it still is waiting
  /// for the [currentStartingDate] to arrive.
  bool get _hasStarted {
    final DateTime now = TimeHelper.instance.currentTime;
    final bool hasStarted = now.isAfter(currentStartingDate);
    return hasStarted;
  }

  /// Returns how many hours a step ([StepData]) lasts.
  int get stepDurationInHours {
    final int duration = steps[0].durationInHours;
    return duration;
  }

  /// Returns how many hours a [TrainingPeriod] lasts.
  int get trainingPeriodDurationInHours {
    final int duration = steps[0].trainingPeriods[0].durationInHours;
    return duration;
  }

  /// Returns how many hours a [Training] lasts.
  int get trainingDurationInHours {
    final int duration =
        steps[0].trainingPeriods[0].trainings[0].durationInHours;
    return duration;
  }

  /// Returns how many [Training]s there are in each [TrainingPeriod].
  int get trainingsPerPeriod {
    final int trainingCount = steps[0].trainingPeriods[0].trainings.length;
    return trainingCount;
  }

  /// Returns whether we're in a different [Training] than when we last checked.
  bool get _inNewTraining {
    final bool inNewTraining;

    final Map<String, dynamic>? activeMap = activeData;
    if (activeMap == null) {
      inNewTraining = true;
    } else {
      final DateTime now = TimeHelper.instance.currentTime;
      final Map<String, dynamic>? currentMap = _getDataByDate(now);
      if (currentMap != null) {
        final Training activeTraining = activeMap['training'] as Training;
        final Training currentTraining = currentMap['training'] as Training;

        if (activeTraining != currentTraining) {
          inNewTraining = true;
        } else {
          inNewTraining = false;
        }
      } else {
        // If we've run out of trainings, act as if we are in a new training
        inNewTraining = true;
      }
    }
    return inNewTraining;
  }

  /// Returns how many [TrainingPeriod]s have gone by since last
  /// opening the app.
  int _getPassedTrainingPeriods({
    required final DateTime startingDate,
    required final DateTime endingDate,
  }) {
    final int passedHours = endingDate.difference(startingDate).inHours;
    final int passedPeriods =
        (passedHours / trainingPeriodDurationInHours).floor();

    return passedPeriods;
  }

  /// Returns the [StepData], the [TrainingPeriod], and the [Training]
  /// that currently are active.
  Map<String, dynamic>? get activeData {
    for (final StepData step in steps) {
      final Map<String, dynamic>? activeData = step.activeData;
      if (activeData != null) {
        return activeData;
      }
    }
  }

  /// Returns the [StepData], the [TrainingPeriod], and the [Training]
  /// that will start the whole training-process off.
  Map<String, dynamic>? get waitingData {
    for (final StepData step in steps) {
      final Map<String, dynamic>? tempResult = step.waitingData;
      if (tempResult != null) {
        return tempResult;
      }
    }
  }

  /// Performs the initial activation of the starting [TrainingPeriod].
  void _activateStartingPeriod() {
    for (final StepData step in steps) {
      step.activateWaitingPeriod();
    }
  }

  /// Moves the [currentStartingDate] so that it is the
  /// starting Date for the current [TrainingPeriod].
  void _setNewStartingDate() {
    final DateTime now = TimeHelper.instance.currentTime;
    final Duration periodDuration =
        Duration(hours: trainingPeriodDurationInHours);

    while ((currentStartingDate.add(periodDuration)).isBefore(now)) {
      print('Moved date one trainingPeriod.');
      currentStartingDate = currentStartingDate.add(periodDuration);
    }
  }

  /// This (re-)sets the dates for all trainings,
  /// the first one starting at [currentStartingDate].
  ///
  /// Define [startingIndexData] to start at a specified trainingPeriod.
  /// Without any arguments, all trainings will be re-dated.
  void _setTrainingDates(
      [final Map<String, int> startingIndexData = const <String, int>{
        'step': 0,
        'trainingPeriod': 0,
      }]) {
    final int startingStepIdx = startingIndexData['step']!;
    final int startingPeriodIdx = startingIndexData['trainingPeriod']!;

    // Set dates for all the trainings
    DateTime workingDate = currentStartingDate;

    for (int i = startingStepIdx; i < steps.length; i++) {
      final StepData step = steps[i];

      if (i == startingStepIdx) {
        workingDate = step.setChildrenDates(workingDate, startingPeriodIdx);
      } else {
        workingDate = step.setChildrenDates(workingDate, 0);
      }
    }
  }

  /// Marks all [TrainingPeriod]s that have passed as being passed.
  ///
  /// Necessary if the user starts with something else than step 1.
  void _completePassedPeriods() {
    for (final StepData step in steps) {
      step.markPassedPeriods();
    }
  }

  /// Returns the [StepData], the [TrainingPeriod], and the [Training]
  /// that aling with on specific [date].
  Map<String, dynamic>? _getDataByDate(final DateTime date) {
    Map<String, dynamic>? map;
    for (final StepData step in steps) {
      map = step.getDataByDate(date);
      if (map != null) {
        return map;
      }
    }
  }

  /// Resets a number of [TrainingPeriod]s ([remainingRegressions],
  /// derived from [failedPeriods]).
  ///
  /// Returns the position of the new current [TrainingPeriod].
  Map<String, int> _penalizeFailure(
    final int failedPeriods,
    final Map<String, dynamic> lastActiveMap,
  ) {
    final int previouslyActivePeriodIdx =
        (lastActiveMap['trainingPeriod'] as TrainingPeriod).index;

    int currentStepIdx = (lastActiveMap['step'] as StepData).index;

    // Always reset one additional period
    // to make sure we actually move backwards in time.
    int remainingRegressions = failedPeriods + 1;

    while (true) {
      final StepData currentStep = steps[currentStepIdx];
      remainingRegressions = currentStep.regressPeriods(remainingRegressions);

      if (remainingRegressions > 0 && currentStepIdx > 0) {
        // If there are more loops to come AND
        // we haven't reached the start of all challenges: Repeat cycle.
        currentStepIdx--;
      } else {
        // If this was the last loop,
        // return the current trainingPeriod's position.
        final int newCurrentStepIdx = currentStepIdx;
        final int newCurrentPeriodIdx;
        if (previouslyActivePeriodIdx == 0) {
          newCurrentPeriodIdx = 0;
        } else {
          newCurrentPeriodIdx = previouslyActivePeriodIdx - failedPeriods;
        }

        final Map<String, int> newCurrentPosition = <String, int>{
          'step': newCurrentStepIdx,
          'trainingPeriod': newCurrentPeriodIdx,
        };
        return newCurrentPosition;
      }
    }
  }

  /// Marks the [HabitPlan] that constructed this [ProgressData]
  /// as having been completed.
  Future<void> _completeHabitPlan() async {
    final HabitPlan? habitPlan =
        await DatabaseHelper.instance.getHabitPlan(habitPlanId);

    if (habitPlan != null) {
      habitPlan.fullyCompleted = true;
      DatabaseHelper.instance.updateHabitPlan(habitPlan);
    }
  }

  /// Analyzes the amount of time that has passed since last time opening
  /// the app. Then adapts [ProgressData] accordingly.
  void _adaptToPassedTime() {
    final Map<String, dynamic> lastActiveMap = activeData!;

    // Analyze the last training
    final Training lastActiveTraining = lastActiveMap['training'] as Training;
    lastActiveTraining.setResult();

    // Analyze the passed trainingPeriods
    // Calculate the number of trainingPeriods passed.
    // For dayly trainings, that would be how many weeks have passed.
    final DateTime now = TimeHelper.instance.currentTime;
    final int passedTrainingPeriods = _getPassedTrainingPeriods(
      startingDate: currentStartingDate,
      endingDate: now,
    );

    if (passedTrainingPeriods >= 1) {
      // Analyze the trainingPeriod that was last active
      final TrainingPeriod lastActivePeriod =
          lastActiveMap['trainingPeriod'] as TrainingPeriod;

      // Get the number of failed trainigPeriods
      int failedPeriods = passedTrainingPeriods;
      if (lastActivePeriod.wasSuccessful) {
        print('WAS SUCCESSFUL!!!!!!!!!!');
        failedPeriods -= 2;
      }

      print('failedPeriods: $failedPeriods');
      _setNewStartingDate();

      final TrainingPeriod lastPeriod = steps.last.trainingPeriods.last;

      if (lastActivePeriod.wasSuccessful && lastActivePeriod == lastPeriod) {
        fullyCompleted = true;
        _completeHabitPlan();
      }

      if (failedPeriods >= 0 || lastActivePeriod == lastPeriod) {
        final Map<String, int> nextPeriodPosition;
        nextPeriodPosition = _penalizeFailure(failedPeriods, lastActiveMap);
        _setTrainingDates(nextPeriodPosition);
      }
    }
  }

  /// Activate the next [Training] & [TrainingPeriod].
  void _activateCurrentTraining() {
    final DateTime now = TimeHelper.instance.currentTime;
    final Map<String, dynamic> currentData = _getDataByDate(now)!;

    final Training currentTraining = currentData['training'] as Training;
    currentTraining.status = 'ready';

    final TrainingPeriod currentPeriod =
        currentData['trainingPeriod'] as TrainingPeriod;
    currentPeriod.status = 'active';
  }

  /// Checks how much time has passed since the last activity and
  /// adapts [ProgressData] (and the database) accordingly.
  bool updateSelf() {
    final bool somethingChanged;

    if (_hasStarted && _inNewTraining) {
      somethingChanged = true;

      if (activeData == null) {
        // If this is the first training we ever arrive in.
        // Necessary for _analyzePassedTime(); to not crash.
        _activateStartingPeriod();
      }

      // Analyze what happened since last time opening the app
      _adaptToPassedTime();

      // Activate the next Training/TrainingPeriod
      _activateCurrentTraining();

      // Save all changes
      DatabaseHelper.instance.updateProgressData(this);
    } else {
      somethingChanged = false;
    }

    return somethingChanged;
  }

  // Functions for interacting with the database

  /// Converts [this] into a Map.
  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> stepMapList = <Map<String, dynamic>>[];

    for (final StepData step in steps) {
      stepMapList.add(step.toMap());
    }

    final Map<String, dynamic> map = <String, dynamic>{
      'habitPlanId': habitPlanId,
      'isActive': isActive.toInt(),
      'fullyCompleted': fullyCompleted.toInt(),
      'currentStartingDate': currentStartingDate.toString(),
      'goal': habit,
      'steps': jsonEncode(stepMapList),
    };
    return map;
  }
}
