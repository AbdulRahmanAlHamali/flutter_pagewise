/// A library for widgets that load their content one page (or batch) at a time.
///
/// The library provides three widgets:
///  * [Pagewise]: An abstract widget that pagewise widgets must extend and
/// implement the [Pagewise.buildPage] function
///  * [PagewiseGridView]: A pagewise implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html). It could be
///  used as follows:
///  ```dart
///  PagewiseGridView(
///    pageSize: 10,
///    totalCount: 40,
///    crossAxisCount: 2,
///    mainAxisSpacing: 8.0,
///    crossAxisSpacing: 8.0,
///    childAspectRatio: 0.555,
///    padding: EdgeInsets.all(15.0),
///    itemBuilder: (context, entry) {
///      // return a widget that displays the entry's data
///    },
///    pageFuture: (pageIndex) {
///      // return a Future that resolves to a list containing the page's data
///    },
///  );
///  ```
///
///  * [PagewiseListView]: A pagewise implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html). It could be
///  used as follows:
///  ```dart
///  PagewiseListView(
///    pageSize: 10,
///    totalCount: 40,
///    padding: EdgeInsets.all(15.0),
///    itemBuilder: (BuildContext context, entry) {
///      // return a widget that displays the entry's data
///    },
///    pageFuture: (pageIndex) {
///      // return a Future that resolves to a list containing the page's data
///    }
///  );
///  ```
///
/// Check the classes' documentation for more details.
///
/// If you don't want to use [PagewiseGridView] or [PagewiseListView], you can
/// implement your own pagewise widget, by extending [Pagewise] class and
/// implementing the _buildWidget function, which takes a page (a list of data)
/// and returns a widget that displays this data. For example, to implement
/// a PagewiseColumn:
/// ```dart
/// @override
/// Widget buildPage(BuildContext context, List page) {
///   return Column(
///     children: page.map((entry) => this.itemBuilder(context, entry)).toList();
///   );
/// }
/// ```
/// Note that in the code above I'm assuming that your implementation uses an
/// itemBuilder function to build a widget for each entry. This, of course, is
/// not necessary.
library flutter_pagewise;

import 'dart:async';

import 'package:flutter/material.dart';

typedef Widget ItemBuilder(BuildContext context, dynamic entry);
typedef Future<List> PageFuture(int pageIndex);
typedef Widget ErrorBuilder(BuildContext context, Object error);
typedef Widget LoadingBuilder(BuildContext context);

/// An abstract base class for widgets that fetch their content one page at a
/// time.
///
/// The widget fetches the page when we scroll down to it, and then keeps it in
/// memory
///
/// You can build your own Pagewise widgets by extending this class and
/// implementing the [buildPage] function which receives the page (or batch) of
/// data as a parameter, and returns a widget that holds this page's data
///
/// See also:
///
///  * [PagewiseGridView], a [Pagewise] implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html)
///  * [PagewiseListView], a [Pagewise] implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html)
abstract class Pagewise extends StatelessWidget {
  /// A store for the pages of data that have already been fetched
  final _pages = <List>[];

  /// The number  of entries per page
  final int pageSize;

  /// The total number of entries.
  final int totalCount;

  /// Called whenever a new page (or batch) is to be fetched
  ///
  /// It is provided with the page index, and expected to return a [Future](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) that
  /// resolves to a list of entries. These entries will be fed to the
  /// [buildPage] function to build the page. Please make sure to return
  /// only [pageSize] or less entries (in the case of the last page) for each
  /// page.
  final PageFuture pageFuture;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController](https://docs.flutter.io/flutter/widgets/PrimaryScrollController-class.html).
  ///
  /// Same as [ScrollView.primary](https://docs.flutter.io/flutter/widgets/ScrollView/primary.html)
  final bool primary;

  /// Whether the extent of the scroll view in the [scrollDirection](https://docs.flutter.io/flutter/widgets/ScrollView/scrollDirection.html) should be
  /// determined by the contents being viewed.
  ///
  /// Same as [ScrollView.shrinkWrap](https://docs.flutter.io/flutter/widgets/ScrollView/shrinkWrap.html)
  final bool shrinkWrap;

  /// Called when loading each page.
  ///
  /// It is expected to return a widget to display while the page is loading.
  /// For example:
  /// ```dart
  /// (BuildContext context) {
  ///   return Text('Loading...');
  /// }
  /// ```
  ///
  /// If not specified, a [CircularProgressIndicator](https://docs.flutter.io/flutter/material/CircularProgressIndicator-class.html) will be shown
  final LoadingBuilder loadingBuilder;

  /// Called with an error object if an error occurs when loading the page
  ///
  /// It is expected to return a widget to display in place of the page that
  /// failed to load. For example:
  /// ```dart
  /// (BuildContext context, Object error) {
  ///   return Text('Failed to load page: $error');
  /// }
  /// ```
  /// If not specified, a [Text] containing the error will be displayed
  final ErrorBuilder errorBuilder;

  /// Creates a pagewise widget.
  ///
  /// This is an abstract class, this constructor should only be called from
  /// constructors of widgets that extend this class
  Pagewise(
      {this.pageSize = 10,
      @required this.totalCount,
      @required this.pageFuture,
      this.padding,
      this.primary,
      this.shrinkWrap = false,
      this.loadingBuilder,
      this.errorBuilder});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: this.padding,
      itemCount: (this.totalCount / this.pageSize).ceil(),
      primary: this.primary,
      shrinkWrap: this.shrinkWrap,
      itemBuilder: (BuildContext context, int index) {
        if (index >= this._pages.length) {
          return FutureBuilder(
            future: this._fetchPage(index),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return this._getLoadingWidget(context);
                default:
                  if (snapshot.hasError) {
                    return this.errorBuilder != null
                        ? this.errorBuilder(context, snapshot.error)
                        : this._getStandardErrorWidget(snapshot.error);
                  } else {
                    return this.buildPage(context, this._pages[index]);
                  }
              }
            },
          );
        } else {
          return this.buildPage(context, this._pages[index]);
        }
      },
    );
  }

  /// Called by the Pagewise component for each page of data to be displayed.
  ///
  /// It is supposed to use the elements of [page] and return a widget that
  /// displays those elements.
  ///
  /// See also:
  ///
  ///  * [PagewiseGridView.buildPage]
  ///  * [PagewiseListView.buildPage]
  Widget buildPage(BuildContext context, List page);

  Widget _getLoadingWidget(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height *
            2, // to only load one page at a time
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
              alignment: Alignment.topCenter,
              child: this.loadingBuilder != null
                  ? this.loadingBuilder(context)
                  : CircularProgressIndicator()),
        ));
  }

  Widget _getStandardErrorWidget(Object error) {
    return Text('Error: $error');
  }

  Future<List> _fetchPage(int pageIndex) async {
    List page = await this.pageFuture(pageIndex);
    // pages might be fetched out of order,
    // so this is code is to make sure the right page is put in the right place
    if (pageIndex == this._pages.length) {
      this._pages.add(page);
    } else if (pageIndex > this._pages.length) {
      while (this._pages.length < pageIndex) {
        this._pages.add([]);
      }
      this._pages.add(page);
    } else {
      this._pages[pageIndex] = page;
    }

    return page;
  }
}

/// A [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html) implementation of [Pagewise]
///
/// Elements are displayed in a grid, but fetched one page (or batch) at a time
class PagewiseGridView extends Pagewise {
  /// Called to build each entry in the view
  ///
  /// It is called for each of the entries fetched by [pageFuture] and provided
  /// with the [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and the entry. It is expected to return the widget
  /// that we want to display for each entry
  ///
  /// For example, the [pageFuture] might return a list that looks like:
  /// ```dart
  ///[
  ///  {
  ///    'name': 'product1',
  ///    'price': 10
  ///  },
  ///  {
  ///    'name': 'product2',
  ///    'price': 15
  ///  },
  ///]
  /// ```
  /// Then itemBuilder will be called twice, once for each entry. We can for
  /// example do:
  /// ```dart
  /// (BuildContext context, dynamic entry) {
  ///   return Text(entry['name'] + ' - ' + entry['price']);
  /// }
  /// ```
  final ItemBuilder itemBuilder;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  ///
  /// Same as [GridView.childAspectRatio](https://docs.flutter.io/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount/childAspectRatio.html)
  final double childAspectRatio;

  /// The number of logical pixels between each child along the main axis.
  ///
  /// Same as [GridView.mainAxisSpacing](https://docs.flutter.io/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount/mainAxisSpacing.html)
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  ///
  /// Same as [GridView.crossAxisSpacing](https://docs.flutter.io/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount/crossAxisSpacing.html)
  final double crossAxisSpacing;

  /// The number of children in the cross axis.
  ///
  /// Same as [GridView.crossAxisCount](https://docs.flutter.io/flutter/rendering/SliverGridDelegateWithFixedCrossAxisCount/crossAxisCount.html)
  final int crossAxisCount;

  /// Creates a pagewise [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html)
  PagewiseGridView(
      {pageSize = 10,
      @required totalCount,
      @required this.itemBuilder,
      @required pageFuture,
      @required this.crossAxisCount,
      this.mainAxisSpacing = 0.0,
      this.crossAxisSpacing = 0.0,
      this.childAspectRatio = 1.0,
      padding,
      primary,
      shrinkWrap = false,
      loadingBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            totalCount: totalCount,
            pageFuture: pageFuture,
            padding: padding,
            primary: primary,
            shrinkWrap: shrinkWrap,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder);

  @override
  Widget buildPage(BuildContext context, List page) {
    return GridView.count(
        shrinkWrap: true,
        primary: false,
        childAspectRatio: this.childAspectRatio,
        padding: EdgeInsets.only(bottom: this.mainAxisSpacing),
        mainAxisSpacing: this.mainAxisSpacing,
        crossAxisSpacing: this.crossAxisSpacing,
        crossAxisCount: this.crossAxisCount,
        children: page.map<Widget>((item) {
          return this.itemBuilder(context, item);
        }).toList());
  }
}

/// A [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html) implementation of [Pagewise]
///
/// Elements are displayed in a list, but fetched one page (or batch) at a time
class PagewiseListView extends Pagewise {
  /// Called to build each entry in the view
  ///
  /// It is called for each of the entries fetched by [pageFuture] and provided
  /// with the [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and the entry. It is expected to return the widget
  /// that we want to display for each entry
  ///
  /// For example, the [pageFuture] might return a list that looks like:
  /// ```dart
  ///[
  ///  {
  ///    'name': 'product1',
  ///    'price': 10
  ///  },
  ///  {
  ///    'name': 'product2',
  ///    'price': 15
  ///  },
  ///]
  /// ```
  /// Then itemBuilder will be called twice, once for each entry. We can for
  /// example do:
  /// ```dart
  /// (BuildContext context, dynamic entry) {
  ///   return Text(entry['name'] + ' - ' + entry['price']);
  /// }
  /// ```
  final ItemBuilder itemBuilder;

  /// Creates a pagewise [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html)
  PagewiseListView(
      {pageSize = 10,
      @required totalCount,
      @required this.itemBuilder,
      @required pageFuture,
      padding,
      primary,
      shrinkWrap = false,
      loadingBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            totalCount: totalCount,
            pageFuture: pageFuture,
            padding: padding,
            primary: primary,
            shrinkWrap: shrinkWrap,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder);

  @override
  Widget buildPage(BuildContext context, List page) {
    return ListView(
        shrinkWrap: true,
        primary: false,
        children: page.map<Widget>((item) {
          return this.itemBuilder(context, item);
        }).toList());
  }
}
