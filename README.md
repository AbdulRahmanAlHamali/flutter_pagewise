# flutter_pagewise

A library for widgets that load their content one page (or batch) at a time.
## Installation
See the [installation instructions on pub](https://pub.dartlang.org/packages/flutter_pagewise#-installing-tab-).
## How to use
The library provides three widgets:
 * [Pagewise](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise-class.html): An abstract widget that pagewise widgets must extend and
implement the [buildPage]((https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise/buildPage.html)) function
 * [PagewiseGridView](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/PagewiseGridView-class.html): A pagewise implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html). It could be
 used as follows:
 ```dart
 PagewiseGridView(
   pageSize: 10,
   totalCount: 40,
   crossAxisCount: 2,
   mainAxisSpacing: 8.0,
   crossAxisSpacing: 8.0,
   childAspectRatio: 0.555,
   padding: EdgeInsets.all(15.0),
   itemBuilder: (context, entry) {
     // return a widget that displays the entry's data
   },
   pageFuture: (pageIndex) {
     // return a Future that resolves to a list containing the page's data
   },
 );
 ```

 * [PagewiseListView](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/PagewiseListView-class.html): A pagewise implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html). It could be
 used as follows:
 ```dart
 PagewiseListView(
   pageSize: 10,
   totalCount: 40,
   padding: EdgeInsets.all(15.0),
   itemBuilder: (BuildContext context, entry) {
     // return a widget that displays the entry's data
   },
   pageFuture: (pageIndex) {
     // return a Future that resolves to a list containing the page's data
   }
 );
 ```

Check the [documentation](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/flutter_pagewise-library.html) for more details.

If you don't want to use [PagewiseGridView](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/PagewiseGridView-class.html) or [PagewiseListView](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/PagewiseListView-class.html), you can
implement your own pagewise widget, by extending [Pagewise](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise-class.html) class and
implementing the [buildWidget](https://pub.dartlang.org/documentation/flutter_pagewise/latest/flutter_pagewise/Pagewise/buildPage.html) function, which takes a page (a list of data)
and returns a widget that displays this data. For example, to implement
a PagewiseColumn:
```dart
@override
Widget buildPage(BuildContext context, List page) {
  return Column(
    children: page.map((entry) => this.itemBuilder(context, entry)).toList();
  );
}
```
Note that in the code above I'm assuming that your implementation uses an
itemBuilder function to build a widget for each entry. This, of course, is
not necessary.
