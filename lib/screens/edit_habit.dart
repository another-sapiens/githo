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
import 'package:flutter/services.dart';

import 'package:githo/config/data_shortcut.dart';
import 'package:githo/config/style_data.dart';

import 'package:githo/helpers/text_form_field_validation.dart';
import 'package:githo/helpers/type_extentions.dart';
import 'package:githo/widgets/background.dart';
import 'package:githo/widgets/dividers/fat_divider.dart';
import 'package:githo/widgets/dividers/thin_divider.dart';

import 'package:githo/widgets/form_list.dart';
import 'package:githo/widgets/headings/screen_title.dart';
import 'package:githo/widgets/headings/heading.dart';
import 'package:githo/widgets/screen_ending_spacer.dart';
import 'package:githo/widgets/slider_title.dart';

import 'package:githo/models/habit_plan.dart';

class EditHabit extends StatefulWidget {
  /// Edit the values of the input [HabitPlan].
  const EditHabit({
    required this.title,
    required this.habitPlan,
    required this.onSavedFunction,
  });

  final String title;
  final HabitPlan habitPlan;
  final Function onSavedFunction;

  @override
  _EditHabitState createState() => _EditHabitState();
}

class _EditHabitState extends State<EditHabit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text used to describe the slider-values
  final List<String> _timeFrames = DataShortcut.timeFrames;
  final List<String> _adjTimeFrames = DataShortcut.adjectiveTimeFrames;
  final List<int> _maxTrainings = DataShortcut.maxTrainings;

  // ignore: use_setters_to_change_properties
  /// Used for receiving the onSaved-values from formList.dart
  void _getStepValues(final List<String> valueList) {
    widget.habitPlan.steps = valueList;
  }

  // ignore: use_setters_to_change_properties
  /// Used for receiving the onSaved-values from formList.dart
  void _getCommentValues(final List<String> valueList) {
    widget.habitPlan.comments = valueList;
  }

  @override
  Widget build(BuildContext context) {
    final int trainingTimeIndex = widget.habitPlan.trainingTimeIndex;
    final String trainingTimeFrame = _timeFrames[trainingTimeIndex];
    final String trainingAdjTimeFrame = _adjTimeFrames[trainingTimeIndex];

    final String periodTimeFrame = _timeFrames[trainingTimeIndex + 1];
    final double currentMaxTrainings =
        _maxTrainings[trainingTimeIndex].toDouble();

    final String firstSliderArticle;
    if (trainingTimeIndex == 0) {
      firstSliderArticle = 'an';
    } else {
      firstSliderArticle = 'a';
    }

    final String thirdSliderText;
    if (widget.habitPlan.requiredTrainingPeriods == 1) {
      thirdSliderText = ' is';
    } else {
      thirdSliderText = 's are';
    }

    return Scaffold(
      body: Background(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: StyleData.screenPadding,
                child: ScreenTitle(widget.title),
              ),
              const FatDivider(),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: StyleData.screenPadding,
                      child: Heading('Final habit'),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: TextFormField(
                        decoration: inputDecoration('The final habit'),
                        maxLength: 40,
                        validator: (String? input) => complainIfEmpty(
                          input: input,
                          toFillIn: 'your final habit',
                        ),
                        initialValue: widget.habitPlan.habit,
                        textInputAction: TextInputAction.next,
                        onSaved: (String? input) =>
                            widget.habitPlan.habit = input.toString().trim(),
                      ),
                    ),
                    const ThinDivider(),

                    Padding(
                      padding: StyleData.screenPadding,
                      child: Heading(
                          '${trainingAdjTimeFrame.capitalize()} action count'),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: TextFormField(
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: inputDecoration('Nr of required actions'),
                        maxLength: 2,
                        validator: (String? input) {
                          final String timeFrameArticle;
                          if (trainingTimeFrame == 'hour') {
                            timeFrameArticle = 'an';
                          } else {
                            timeFrameArticle = 'a';
                          }
                          return validateNumberField(
                            input: input,
                            maxInput: 99,
                            toFillIn: 'the required repetitions',
                            textIfZero: 'It has to be at least one '
                                'rep $timeFrameArticle $trainingTimeFrame',
                          );
                        },
                        initialValue: widget.habitPlan.requiredReps.toString(),
                        textInputAction: TextInputAction.next,
                        onSaved: (String? input) => widget.habitPlan
                            .requiredReps = int.parse(input.toString().trim()),
                      ),
                    ),
                    const ThinDivider(),

                    // Create the step-form-fields
                    const Padding(
                      padding: StyleData.screenPadding,
                      child: Heading('Steps towards the habit'),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: FormList(
                        fieldName: 'Step',
                        canBeEmpty: false,
                        valuesGetter: _getStepValues,
                        initValues: widget.habitPlan.steps,
                      ),
                    ),
                    const ThinDivider(),

                    // Create the form-fields for your personal comments
                    Padding(
                      padding: StyleData.screenPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const <Widget>[
                          Heading('Comments'),
                          Text('(Optional)', style: StyleData.textStyle),
                        ],
                      ),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: FormList(
                        fieldName: 'Comment',
                        canBeEmpty: true,
                        valuesGetter: _getCommentValues,
                        initValues: widget.habitPlan.comments,
                      ),
                    ),

                    // Extended settings
                    const FatDivider(),
                    const Padding(
                      padding: StyleData.screenPadding,
                      child: Heading('Extended Settings'),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: SliderTitle(<List<String>>[
                        <String>['normal', 'It will be $firstSliderArticle '],
                        <String>['bold', trainingAdjTimeFrame],
                        const <String>['normal', ' habit.'],
                      ]),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: Slider(
                        value: widget.habitPlan.trainingTimeIndex.toDouble(),
                        // It is -2 BECAUSE
                        //-1: .length return a value that is 1 too large AND
                        //-1: I want exclude the last value.
                        max: (_timeFrames.length - 2).toDouble(),
                        divisions: _timeFrames.length - 2,
                        onChanged: (final double value) {
                          setState(() {
                            final int newTimeIndex = value.toInt();

                            // Set the correct value for THIS slider
                            widget.habitPlan.trainingTimeIndex = newTimeIndex;

                            // Correct the Value for the NEXT slider
                            final double newMaxTrainings =
                                _maxTrainings[newTimeIndex].toDouble();
                            widget.habitPlan.requiredTrainings =
                                (newMaxTrainings * 0.9).floor();
                          });
                        },
                      ),
                    ),
                    const ThinDivider(),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: SliderTitle(<List<String>>[
                        <String>['normal', 'Every $periodTimeFrame, '],
                        <String>[
                          'bold',
                          '${widget.habitPlan.requiredTrainings} '
                        ],
                        <String>[
                          'normal',
                          '''
out of ${currentMaxTrainings.toInt()}
${trainingTimeFrame}s must be successful.'''
                        ]
                      ]),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: Slider(
                        value: widget.habitPlan.requiredTrainings.toDouble(),
                        min: 1,
                        max: currentMaxTrainings,
                        divisions: currentMaxTrainings.toInt() - 1,
                        onChanged: (final double value) {
                          setState(() {
                            widget.habitPlan.requiredTrainings = value.toInt();
                          });
                        },
                      ),
                    ),
                    const ThinDivider(),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: SliderTitle(<List<String>>[
                        <String>[
                          'bold',
                          '${widget.habitPlan.requiredTrainingPeriods} '
                        ],
                        <String>[
                          'normal',
                          '''
successful $periodTimeFrame$thirdSliderText required
to advance to the next step.'''
                        ]
                      ]),
                    ),
                    Padding(
                      padding: StyleData.screenPadding,
                      child: Slider(
                        value:
                            widget.habitPlan.requiredTrainingPeriods.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (final double value) {
                          setState(() {
                            widget.habitPlan.requiredTrainingPeriods =
                                value.toInt();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ScreenEndingSpacer(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Save',
        backgroundColor: Colors.green,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            widget.onSavedFunction(widget.habitPlan);
            Navigator.pop(context);
          }
        },
        child: const Icon(
          Icons.save,
          color: Colors.white,
        ),
      ),
    );
  }
}
