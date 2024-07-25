## Overview

## What problem does this package solve?

### In brief: 
You have a ScrollView with a bunch of arbitrarily sized children, and you want to scroll to a specific child.

### Less brief: 
Imagine you have a ListView that has seven Cards as its children. Each of these Cards contains two or three Widgets
that let the user give some input (TextFields, RadioButtons, etc.). At the bottom of the ListView, there is a Button
"Continue" that is only active when the user has filled out all the input Widgets.

Now, as a user, I scroll down, enter my input as requested until I arrive at the bottom of the ListView, aka. at the continue button. But what is this? The button is not active. Did I forget entering something, or gave invalid input somewhere?

With the help of this package, you could provide a "What did I miss?" button that when pressed, scrolls the 
user exactly to the Widget that needs his attention.


## Why do you need this package for that?
Because Flutter does not provide a way to scroll to a specific Widget in a ScrollView *unless all of the widgets in the ScrollView have the same size in the main axis*. And even then, it gets messy. 

Without this package, if you want to scroll to a specific widget in your scroll view, you need to keep track of the indices of your widgets, then figure out the index of the widget you want to scroll to and calculate the scroll offset by multiplying the index with the 
fixed size of the widgets in that scroll view. This is messy and again, requires all Widgets to have the same height (for vertical ScrollViews) / width (for horizontal ScrollViews).

With this package, you can dynamically scroll to any widget in your ScrollView, and provide fine grained selection logic to determine which Widget you want to scroll to (e.g., in the example above, you would probably want to scroll to the *upmost* Widget that has invalid input). And it does not require the Widgets in the ScrollView to have the same size.


## Usage

In the following example, the scroll logic revolves around categories that are either valid or invalid. (A category in this case correlates with what we previously described as a Card widget with a bunch of inputs - in the example above. But in this example code, a category widget is just a colored container for the sake of simplicity.)


This is just one way of using this package. Check out the components overview below to see what each component does and how you can fit this package to your purpose.


```dart
import 'package:flutter/material.dart';
import 'package:outcome_types/outcome_types.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_specific_widget/presentation/scroll_candidate.dart';
import 'package:scroll_to_specific_widget/scroll_to_specific_widget.dart';

enum Category { A, B, C, D }

enum ValidationStatus { valid, invalid }

class _CategoryA extends StatelessWidget {
  const _CategoryA();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.A,
      child: Container(
        height: 400,
        color: Colors.red,
      ),
    );
  }
}

class _CategoryB extends StatelessWidget {
  const _CategoryB();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.B,
      child: Container(
        height: 600,
        color: Colors.green,
      ),
    );
  }
}

class _CategoryC extends StatelessWidget {
  const _CategoryC();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.C,
      child: Container(
        height: 800,
        color: Colors.blue,
      ),
    );
  }
}

class _CategoryD extends StatelessWidget {
  const _CategoryD();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.D,
      child: Container(
        height: 1000,
        color: Colors.purple,
      ),
    );
  }
}

class _CandidateSelectorDelegate
    implements ScrollCandidateSelectorDelegate<Category> {
  final _categoriesByStatus = <ValidationStatus, List<Category>>{};

  void updateValidationStatus(
    Map<Category, ValidationStatus> categoryToValidationStatus,
  ) {
    _categoriesByStatus.clear();
    for (final MapEntry(key: key, value: value)
        in categoryToValidationStatus.entries) {
      (_categoriesByStatus[value] ??= []).add(key);
    }
  }

  // Selects the upmost invalid category (aka. with smallest scroll offset)
  @override
  Option<ScrollCandidate> selectCandidate(
    Map<Category, Option<ScrollCandidate>> registeredCandidates,
  ) {
    final invalidCategories =
        _categoriesByStatus[ValidationStatus.invalid] ?? [];

    Option<ScrollCandidate> topmostScrollCandidate = const None();

    for (final MapEntry(key: category, value: scrollCandidate)
        in registeredCandidates.entries) {
      if (invalidCategories.contains(category)) {
        if (scrollCandidate case Some(value: final event)) {
          if (topmostScrollCandidate case Some(value: final topmost)) {
            if (event.scrollOffset < topmost.scrollOffset) {
              topmostScrollCandidate = Some(event);
            }
          } else {
            topmostScrollCandidate = Some(event);
          }
        } else {
          assert(false, 'scroll event callback returned None()');
        }
      }
    }

    return topmostScrollCandidate;
  }
}

class Example extends StatefulWidget {
  const Example();

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  // In a real app, this would not be static and instead be updated
  // accordingly whenever the user input changes.
  static const categoryToValidationStatus = <Category, ValidationStatus>{
    Category.A: ValidationStatus.valid,
    Category.B: ValidationStatus.invalid,
    Category.C: ValidationStatus.invalid,
    Category.D: ValidationStatus.valid,
  };

  final _scrollController = ScrollController();
  final _candidateSelectorDelegate = _CandidateSelectorDelegate();

  @override
  void initState() {
    super.initState();
    _candidateSelectorDelegate
        .updateValidationStatus(categoryToValidationStatus);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (_, __) => Builder(
        builder: (context) {
          return ScrollCoordinatorConnector(
            scrollController: _scrollController,
            candidateSelectorDelegate: _candidateSelectorDelegate,
            child: Builder(
              builder: (context) {
                return ListView(
                  controller: _scrollController,
                  children: [
                    const _CategoryA(),
                    const SizedBox(height: 8),
                    const _CategoryB(),
                    const SizedBox(height: 8),
                    const _CategoryC(),
                    const SizedBox(height: 8),
                    const _CategoryD(),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ScrollCoordinator<Category>>()
                          .triggerScroll(),
                      child: const Text('What did I miss?'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const Example());
}
```

## The key parameter K
TL;DR: use an enum

Before we get to the components, lets quickly address their type parameter \<K\>.

K is the type of key that will be used to keep track of the widgets that are possible scroll targets.
It is also the only information about each of these widgets that you can use in your selection logic.
Because of these facts, there are a few requirements for this type:

- It has to contain the information you need to decide whether you want to scroll to the related widget OR provide a way to access that information (e.g. being a key in a map as in our example)
- It has to have value based equality (aka. it should be a [Value-Object in the sense of DDD](https://www.dremio.com/wiki/value-object/))
- It has to be unique within the context of its `ScrollCoordinator`

In our example, we use an enum with a value for each widget. That works just fine, and is the recommended approach. Technically, you could also use numbers or strings, but using numbers will make it cumbersome to select a target candidate and using strings is inferior to using enums in every way.

You could also use immutable classes that contain additional information and update the ScrollCandidateCallbackRegisterer widgets with new instances of these classes when new information is available. It's a viable approach, but we think it's cleaner to store the concrete information you need for the selection of the scroll candidate somewhere else, and just make K a key used for accessing this information (in our example, the actual information we use for the selection is stored within `_CandidateSelectorDelegate._categoriesByStatus`, and K is just the key that we use to access this information for each category).

## Components
Let's go through the components that make all of this work:

### ScrollCoordinatorConnector<K>
  - Wraps the ScrollView containing the Widgets that you want to scroll to
  - Provides a `ScrollCoordinator` to the context for its children to access
  - Is responsible for calling `ScrollController.animateTo` when the `ScrollCoordinator` emits a `ScrollCandidate`

### ScrollCandidateSelectorDelegate<K>
  - You need to provide an implementation of this interface to your `ScrollCoordinatorConnector`
  - `ScrollCandidateSelectorDelegate.selectCandidate` is responsible for selecting a `ScrollCandidate` when a scroll is triggered
  - Your implementation of this interface is how you make this package work for your use-case

### ScrollCoordinator<K>
  - Receives registrations of `ScrollCandidate` callbacks from `ScrollCandidateCallbackRegisterer`
  - When `ScrollCoordinator.triggerScroll` is called, it uses the provided `ScrollCandidateSelectorDelegate` to select which (if any) `ScrollCandidate` to scroll to
  - If a `ScrollCandidate` is selected, it emits that `ScrollCandidate` through a stream that the `ScrollCoordinatorConnector` listens to

### ScrollCandidateCallbackRegisterer<K>
  - Wraps the widgets you potentially want to scroll to
  - Registers a `ScrollCandidate` callback with the nearest ancestor `ScrollCoordinatorConnector`
  - When a scroll is triggered, the `ScrollCoordinator` will call this interface's `selectCandidate` function to select a `ScrollCandidate`

### ScrollCandidate
  - Contains a scroll offset as well as an optional `VoidCallback` `onScrollToOffset`


## Are all of these components really necessary?
Maybe not. Any suggestions to reduce the complexity of this package are more than welcome.