A library for widgets that load their content one page (or batch) at a time (also known as lazy-loading).

<img src="https://raw.githubusercontent.com/AbdulRahmanAlHamali/flutter_pagewise/master/flutter_pagewise.gif">

## Features
* Load data one page at a time
* Retry failed pages
* Override the default loading, retry, and error widgets if desired
* ListView and GridView implementations
* Extendability using inheritance

## Breaking Change Starting V1.0.0:
The library has been rewritten in version 1.0.0 to provide a more
efficient implementation that does not require a `totalCount` parameter
and shows only one loading sign when users scroll down. In addition,
a new parameter has been added to `itemBuilder` callback to provide
the index if needed by the user.

## Installing the library:

Like any other package, add the library to your pubspec.yaml dependencies:
```
dependencies:
    flutter_pagewise:
```
Then import it wherever you want to use it:
```
import 'package:flutter_pagewise/flutter_pagewise.dart';
```

## Using the library
The library provides two main widgets:
 * [PagewiseGridView]: A pagewise implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html). It could be
 used as follows:
 ```dart
 PagewiseGridView.count(
   pageSize: 10,
   crossAxisCount: 2,
   mainAxisSpacing: 8.0,
   crossAxisSpacing: 8.0,
   childAspectRatio: 0.555,
   padding: EdgeInsets.all(15.0),
   itemBuilder: (context, entry, index) {
     // return a widget that displays the entry's data
   },
   pageFuture: (pageIndex) {
     // return a Future that resolves to a list containing the page's data
   },
 );
 ```

 * [PagewiseListView]: A pagewise implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html). It could be
 used as follows:
 ```dart
 PagewiseListView(
   pageSize: 10,
   padding: EdgeInsets.all(15.0),
   itemBuilder: (context, entry, index) {
     // return a widget that displays the entry's data
   },
   pageFuture: (pageIndex) {
     // return a Future that resolves to a list containing the page's data
   }
 );
 ```

The classes provide all the properties of `ListViews` and
`GridViews`. In addition, you must provide the [itemBuilder], which
tells Pagewise how you want to render each element, and [pageFuture],
which Pagewise calls to fetch new pages. Please note that `pageFuture`
must not return more values than mentioned in the [pageSize] parameter.

## Customizing the widget:
In addition to the required parameters, Pagewise provides you with
optional parameters to customize the widget. You have [loadingBuilder],
[errorBuilder], and [retryBuilder] to customize the widgets that show
on loading, error, and retry respectively.

The `loadingBuilder` can be used as follows:
```
loadingBuilder: (context) {
  return Text('Loading...');
}
```

The `retryBuilder` can be used as follows:
```
retryBuilder: (context, callback) {
  return RaisedButton(
    child: Text('Retry'),
    onPressed: () => callback()
  );
}
```
Thus, the `retryBuilder` provides you with a callback that you can
call when you want to retry.

The `errorBuilder` is only relevant when `showRetry` is set to `false`,
because, otherwise, the `retryBuilder` is shown instead. The `errorBuilder`
can be used as follows:
```
errorBuilder: (context, error) {
  return Text('Error: $error');
}
```

Check the classes' documentation for more details.

## Creating your own Pagewise Widgets:
You need to inherit from the [Pagewise] class. Check the code of
[PagewiseListView] and [PagewiseGridView] for examples
