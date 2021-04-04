## 2.0.1 - 04-May-2021

- PR#100 - Various tweaks to the null-safety code and Android fixes

## 2.0.0 - 02/04/2021

- Null Safety

## 1.2.3 - 27/03/2019

- Handle a null Future return when loading a page. We assume a null Future is the same as an empty one.

## 1.2.2 - 06/02/2019

- Fix environment in pubspec.yaml to remove health complaint on dart website

## 1.2.1 - 06/02/2019

- Fixes the `GridView` exception in case the number of items in the last page is less than page size (issues #35, #33)
- Fixes the race condition that might cause the same page to be fetched multiple times (Issues #6, #30)
- Improves types, generic types, and default values on parameters (Issues #24, #25, #32)
- Implements fixes and improvements to the README and the example

## 1.2.0 - 19/12/2018

- Add scenario of moving from one widget.controller to another in didUpdateWidget
- Implement noItemsFoundBuilder

## 1.1.1 - 18/12/2018

- Add `didUpdateWidget` to `PagewiseState` class for cases of switching controller

## 1.1.0 - 18/12/2018

- Implement controller pattern for more control and visibility over page loading
- Provide support for slivers (PagewiseSliverList and PagewiseSliverGrid)

## 1.0.0 - 16/12/2018

- Re-architect the library for more efficiency and ease of use.

## 0.5.0 - 22/08/2018

- Provide ability to retry
- Fix case of page futures refiring when rebuilt

## 0.4.1 - 17/08/2018

- Decrease size of GIF in README to make it load faster

## 0.4.0 - 11/08/2018

- Make future final in \_FutureBuilderWrapper
- Remove unneeded \_pages data structure and operations
- Provide `ItemListBuilder` for cases where we want to build a list of widgets for each data entry
- Provide [controller](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise/errorBuilder.html) property to allow custom [ScrollController](https://docs.flutter.io/flutter/widgets/ScrollController-class.html)

## 0.3.0 - 04/08/2018.

- Wrap the internally used [FutureBuilder](https://docs.flutter.io/flutter/widgets/FutureBuilder-class.html) by an [AutomaticKeepAliveClientMixin](https://docs.flutter.io/flutter/widgets/AutomaticKeepAliveClientMixin-class.html) to prevent from re-firing, causing unnecessary traffic, and scrolling issues in some scenarios
- Provide a key parameter for all the widgets
- Make the [ItemBuilder](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/ItemBuilder.html) accept generic values

## 0.2.0 - 31/07/2018.

- Replace loadingWidget with a loadingBuilder that accepts a [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and returns a widget.
- Fix environment constraints in pubspec.yaml
- Make the example better looking, and the demo as well
- Mention lazy-loading in the README.
- Reformat the code using _flutter format_

## 0.1.2 - 29/07/2018.

- Add gif to README.

## 0.1.1 - 29/07/2018.

- Small fix to README.

## 0.1.0 - 29/07/2018.

- Provided basic functionality for Pagewise class, PagewiseGridView class and PagewiseListView class.
