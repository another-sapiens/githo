import 'package:flutter/material.dart';

import 'package:githo/extracted_data/styleData.dart';
import 'package:githo/extracted_data/fullDatabaseImport.dart';

import 'package:githo/extracted_functions/editHabitRoutes.dart';
import 'package:githo/extracted_widgets/buttonListItem.dart';
import 'package:githo/extracted_widgets/dividers/fatDivider.dart';

import 'package:githo/extracted_widgets/headings.dart';
import 'package:githo/extracted_widgets/screenEndingSpacer.dart';

import 'package:githo/screens/habitDetails.dart';

class HabitList extends StatefulWidget {
  final Function updateFunction;
  const HabitList({required this.updateFunction});

  @override
  _HabitListState createState() =>
      _HabitListState(updatePrevScreens: updateFunction);
}

class _HabitListState extends State<HabitList> {
  final Function updatePrevScreens;
  late Future<List<HabitPlan>> _habitPlanListFuture;

  _HabitListState({
    required this.updatePrevScreens,
  });

  @override
  void initState() {
    super.initState();
    _habitPlanListFuture = DatabaseHelper.instance.getHabitPlanList();
  }

  void _updateLoadedScreens() {
    setState(() {
      _habitPlanListFuture = DatabaseHelper.instance.getHabitPlanList();
      updatePrevScreens();
    });
  }

  List<HabitPlan> _orderHabitPlans(List<HabitPlan> habitPlanList) {
    // Order the habitPlans in a way that displays the most cecently edited ones at the top
    habitPlanList.sort((a, b) {
      String dateStringA = a.lastChanged.toString();
      String dateStringB = b.lastChanged.toString();
      return dateStringB.compareTo(dateStringA);
    });
    return habitPlanList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _habitPlanListFuture,
        builder: (context, AsyncSnapshot<List<HabitPlan>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              List<HabitPlan> habitPlanList = snapshot.data!;

              if (habitPlanList.length == 0) {
                // If there are no habit plans
                return Padding(
                  padding: StyleData.screenPadding,
                  child: const ScreenTitle(
                    title: "List of habits",
                    subTitle: "Please add a habit plan.",
                  ),
                );
              } else {
                // If there are habit plans
                final List<Widget> columnItems = [];
                columnItems.addAll([
                  Padding(
                    padding: StyleData.screenPadding,
                    child: const ScreenTitle(
                      title: "List of habits",
                      subTitle: "Click on a habit-plan to look at it.",
                    ),
                  ),
                  FatDivider(),
                ]);

                final List<HabitPlan> orderedHabitPlans =
                    _orderHabitPlans(habitPlanList);

                columnItems.add(
                  Expanded(
                    child: ListView.builder(
                      padding: StyleData.screenPadding,
                      physics: BouncingScrollPhysics(),
                      itemCount: orderedHabitPlans.length + 1,
                      itemBuilder: (BuildContext buildContex, int i) {
                        if (i < orderedHabitPlans.length) {
                          final HabitPlan habitPlan = orderedHabitPlans[i];

                          return ButtonListItem(
                            text: habitPlan.goal,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleHabitDisplay(
                                    updateFunction: _updateLoadedScreens,
                                    habitPlan: habitPlan,
                                  ),
                                ),
                              );
                            },
                            color: habitPlan.isActive
                                ? Colors.green
                                : Theme.of(context).buttonColor,
                          );
                        } else {
                          // On the last loop, add the ScreenEndingSpacer.
                          return ScreenEndingSpacer();
                        }
                      },
                    ),
                  ),
                );
                return Column(
                  children: columnItems,
                  mainAxisAlignment: MainAxisAlignment.start,
                );
              }
            } else if (snapshot.hasError) {
              // If something went wrong with the database
              print(snapshot.error);

              return Padding(
                padding: StyleData.screenPadding,
                child: Column(
                  children: [
                    const Heading(
                        "There was an error connecting to the database."),
                    Text(
                      snapshot.error.toString(),
                      style: StyleData.textStyle,
                    ),
                  ],
                ),
              );
            }
          }
          // While loading, do this:
          return Center(
            child: const CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          addNewHabit(context, _updateLoadedScreens);
        },
        heroTag: null,
      ),
    );
  }
}
