## 0.1.0 - 29/07/2018.

* Provided basic functionality for Pagewise class, PagewiseGridView class and PagewiseListView class.
## 0.1.1 - 29/07/2018.

* Small fix to README.
## 0.1.2 - 29/07/2018.

* Add  gif to README.

## 0.2.0 - 31/07/2018.

* Replace loadingWidget with a loadingBuilder that accepts a [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and returns a widget.
* Fix environment constraints in pubspec.yaml
* Make the example better looking, and the demo as well
* Mention lazy-loading in the README.
* Reformat the code using *flutter format*

## 0.3.0 - 04/08/2018.

* Wrap the internally used [FutureBuilder](https://docs.flutter.io/flutter/widgets/FutureBuilder-class.html) by an [AutomaticKeepAliveClientMixin](https://docs.flutter.io/flutter/widgets/AutomaticKeepAliveClientMixin-class.html) to prevent from re-firing, causing unnecessary traffic, and scrolling issues in some scenarios
* Provide a key parameter for all the widgets
* Make the [ItemBuilder](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/ItemBuilder.html) accept generic values

## 0.4.0 - 11/08/2018

* Make future final in _FutureBuilderWrapper
* Remove unneeded _pages data structure and operations
* Provide [ItemListBuilder](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/ItemListBuilder.html) for cases where we want to build a list of widgets for each data entry
* Provide [controller](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise/errorBuilder.html) property to allow custom [ScrollController](https://docs.flutter.io/flutter/widgets/ScrollController-class.html)

## 0.4.1 - 17/08/2018

* Decrease size of GIF in README to make it load faster