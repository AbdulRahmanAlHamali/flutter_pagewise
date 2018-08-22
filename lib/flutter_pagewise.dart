/// A library for widgets that load their content one page (or batch) at a time (also known as lazy-loading).
///
/// ## Features
/// * Load data one page at a time
/// * Retry failed pages
/// * Override the default loading, retry, and error widgets if desired
/// * ListView and GridView implementations
/// * Extendability using inheritance
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
import 'package:async/async.dart';

typedef Widget ItemBuilder<T>(BuildContext context, T entry);
typedef List<Widget> ItemListBuilder<T>(BuildContext context, T entry);
typedef Future<List> PageFuture(int pageIndex);
typedef Widget ErrorBuilder(BuildContext context, Object error);
typedef Widget LoadingBuilder(BuildContext context);
typedef Widget RetryBuilder(BuildContext context, RetryCallback retryCallback);
typedef void RetryCallback();

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

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Same as [ScrollView.controller](https://docs.flutter.io/flutter/widgets/ScrollView/controller.html)
  final ScrollController controller;

  /// Whether to show a retry button when page fails to load.
  ///
  /// If set to true, [retryBuilder] is called to show appropriate retry button.
  ///
  /// If set to false, [errorBuilder] is called instead to show appropriate
  /// error.
  final bool showRetry;

  /// Called when a page fails to load and [showRetry] is set to true.
  ///
  /// It is expected to return a widget that gives the user the idea that retry
  /// is possible. The builder is provided with a [RetryCallback] that must be
  /// called for the retry to happen.
  ///
  /// For example:
  /// ```dart
  /// (context, retryCallback) {
  ///   return FloatingActionButton(
  ///     onPressed: retryCallback,
  ///     backgroundColor: Colors.red,
  ///     child: Icon(Icons.refresh),
  ///   );
  /// }
  /// ```
  ///
  /// In the code above, when the button is pressed, retryCallback is called,
  /// which will retry to fetch the page.
  ///
  /// If not specified, a simple retry button will be shown
  final RetryBuilder retryBuilder;

  /// Creates a pagewise widget.
  ///
  /// This is an abstract class, this constructor should only be called from
  /// constructors of widgets that extend this class
  Pagewise(
      {this.pageSize = 10,
      @required this.totalCount,
      @required this.pageFuture,
      Key key,
      this.padding,
      this.primary,
      this.controller,
      this.shrinkWrap = false,
      this.loadingBuilder,
      this.retryBuilder,
      this.showRetry,
      this.errorBuilder}) :
        assert(showRetry != null),
        assert(showRetry == false || errorBuilder == null, 'Cannot specify showRetry and errorBuilder at the same time'),
        assert(showRetry == true || retryBuilder == null, "Cannot specify retryBuilder when showRetry is set to false"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: this.controller,
      padding: this.padding,
      itemCount: (this.totalCount / this.pageSize).ceil(),
      primary: this.primary,
      shrinkWrap: this.shrinkWrap,
      itemBuilder: (BuildContext context, int pageNumber) {
        return _Page(
          pageFuture: this.pageFuture,
          pageNumber: pageNumber,
          loadingBuilder: this.loadingBuilder,
          errorBuilder: this.errorBuilder,
          pageBuilder: this.buildPage,
          showRetry: this.showRetry,
          retryBuilder: this.retryBuilder,
        );
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
}


typedef Widget _PageBuilder(BuildContext context, List page);
/// This is a private class that represents a page, and wraps it with [AutomaticKeepAliveClientMixin](https://docs.flutter.io/flutter/widgets/AutomaticKeepAliveClientMixin-class.html)
///
/// This is needed to keep the fetched pages alive, and maintain their state.
class _Page extends StatefulWidget {

  final LoadingBuilder loadingBuilder;
  final ErrorBuilder errorBuilder;
  final _PageBuilder pageBuilder;
  final bool showRetry;
  final RetryBuilder retryBuilder;
  final PageFuture pageFuture;
  final int pageNumber;

  _Page({
    this.loadingBuilder,
    this.errorBuilder,
    this.pageBuilder,
    this.showRetry,
    this.retryBuilder,
    this.pageFuture,
    this.pageNumber
  });

  @override
  _PageState createState() => _PageState();
}

class _PageState<T> extends State<_Page> with AutomaticKeepAliveClientMixin {

  AsyncMemoizer _memoizer;

  @override
  void initState() {
    super.initState();
    this._memoizer = new AsyncMemoizer();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this._memoizer.runOnce(() => widget.pageFuture(widget.pageNumber)),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return this._getLoadingWidget(context);
          default:
            if (snapshot.hasError) {
              if (widget.showRetry == false) {
                return widget.errorBuilder != null
                    ? widget.errorBuilder(context, snapshot.error)
                    : this._getStandardErrorWidget(snapshot.error);
              } else {
                return this._getRetryWidget(context);
              }
            } else {
              return widget.pageBuilder(context, snapshot.data);
            }
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _getLoadingWidget(BuildContext context) {
    return SizedBox(
        height: MediaQuery.of(context).size.height *
            2, // to only load one page at a time
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
              alignment: Alignment.topCenter,
              child: widget.loadingBuilder != null
                  ? widget.loadingBuilder(context)
                  : CircularProgressIndicator()),
        ));
  }

  Widget _getRetryWidget(BuildContext context) {

    var defaultRetryButton = FlatButton(
      child: Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      color: Colors.grey[300],
      shape: CircleBorder(),
      onPressed: this._retry,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: widget.retryBuilder != null
            ? widget.retryBuilder(context, this._retry)
            : defaultRetryButton
      ),
    );
  }

  void _retry() {
    setState(() {
      this._memoizer = AsyncMemoizer();
    });
  }

  Widget _getStandardErrorWidget(Object error) {
    return Text('Error: $error');
  }
}


/// A [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html) implementation of [Pagewise]
///
/// Elements are displayed in a grid, but fetched one page (or batch) at a time
class PagewiseGridView extends Pagewise {
  /// Called to build each entry in the view when we want each entry to
  /// correspond to a single widget.
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
  /// The itemBuilder returns a single widget, if you want to return a list of
  /// widgets. For example, a [ListTile](https://docs.flutter.io/flutter/material/ListTile-class.html)
  /// followed by a [Divider](https://docs.flutter.io/flutter/material/Divider-class.html),
  /// then use the [itemListBuilder] instead.
  final ItemBuilder itemBuilder;

  /// Called to build each entry in the view when we want each entry to
  /// correspond to a list of widgets.
  ///
  /// This is useful when, for example, we want to display a [ListTile](https://docs.flutter.io/flutter/material/ListTile-class.html)
  /// followed by a [Divider](https://docs.flutter.io/flutter/material/Divider-class.html)
  /// for each entry.
  ///
  /// It is called for each of the entries fetched by [pageFuture] and provided
  /// with the [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and the entry. It is expected to return a list of widgets
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
  /// Then itemListBuilder will be called twice, once for each entry. We can for
  /// example do:
  /// ```dart
  /// (BuildContext context, dynamic entry) {
  ///   return [
  ///     Text(entry['name'] + ' - ' + entry['price']),
  ///     Divider()
  ///   ];
  /// }
  /// ```
  /// The itemListBuilder returns a list of widgets, if you want to return a
  /// single widget, then use the [itemBuilder] instead.
  final ItemListBuilder itemListBuilder;

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
      this.itemBuilder,
      this.itemListBuilder,
      @required pageFuture,
      @required this.crossAxisCount,
      Key key,
      this.mainAxisSpacing = 0.0,
      this.crossAxisSpacing = 0.0,
      this.childAspectRatio = 1.0,
      padding,
      controller,
      primary,
      shrinkWrap = false,
      loadingBuilder,
      showRetry = true,
      retryBuilder,
      errorBuilder})
      : assert(itemBuilder == null || itemListBuilder == null, "Cannot have both itemBuilder and itemListBuilder"),
        assert(itemBuilder != null || itemListBuilder != null, "Either itemBuilder or itemListBuilder must be specified and not equal to null"),
        super(
            key: key,
            pageSize: pageSize,
            totalCount: totalCount,
            pageFuture: pageFuture,
            padding: padding,
            controller: controller,
            primary: primary,
            shrinkWrap: shrinkWrap,
            loadingBuilder: loadingBuilder,
            showRetry: showRetry,
            retryBuilder: retryBuilder,
            errorBuilder: errorBuilder);

  @override
  Widget buildPage(BuildContext context, List page) {

    List<Widget> children = this.itemBuilder != null?
      page.map<Widget>((item) => this.itemBuilder(context, item)).toList() :
      page.expand<Widget>((item) => this.itemListBuilder(context, item)).toList();

    return GridView.count(
        shrinkWrap: true,
        primary: false,
        childAspectRatio: this.childAspectRatio,
        padding: EdgeInsets.only(bottom: this.mainAxisSpacing),
        mainAxisSpacing: this.mainAxisSpacing,
        crossAxisSpacing: this.crossAxisSpacing,
        crossAxisCount: this.crossAxisCount,
        children: children
    );
  }
}

/// A [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html) implementation of [Pagewise]
///
/// Elements are displayed in a list, but fetched one page (or batch) at a time
class PagewiseListView extends Pagewise {
  /// Called to build each entry in the view when we want each entry to
  /// correspond to a single widget.
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
  /// The itemBuilder returns a single widget, if you want to return a list of
  /// widgets. For example, a [ListTile](https://docs.flutter.io/flutter/material/ListTile-class.html)
  /// followed by a [Divider](https://docs.flutter.io/flutter/material/Divider-class.html),
  /// then use the [itemListBuilder] instead.
  final ItemBuilder itemBuilder;

  /// Called to build each entry in the view when we want each entry to
  /// correspond to a list of widgets.
  ///
  /// This is useful when, for example, we want to display a [ListTile](https://docs.flutter.io/flutter/material/ListTile-class.html)
  /// followed by a [Divider](https://docs.flutter.io/flutter/material/Divider-class.html)
  /// for each entry.
  ///
  /// It is called for each of the entries fetched by [pageFuture] and provided
  /// with the [BuildContext](https://docs.flutter.io/flutter/widgets/BuildContext-class.html) and the entry. It is expected to return a list of widgets
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
  /// Then itemListBuilder will be called twice, once for each entry. We can for
  /// example do:
  /// ```dart
  /// (BuildContext context, dynamic entry) {
  ///   return [
  ///     Text(entry['name'] + ' - ' + entry['price']),
  ///     Divider()
  ///   ];
  /// }
  /// ```
  /// The itemListBuilder returns a list of widgets, if you want to return a
  /// single widget, then use the [itemBuilder] instead.
  final ItemListBuilder itemListBuilder;

  /// Creates a pagewise [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html)
  PagewiseListView(
      {pageSize = 10,
      @required totalCount,
      this.itemBuilder,
      this.itemListBuilder,
      @required pageFuture,
      Key key,
      padding,
      primary,
      controller,
      shrinkWrap = false,
      loadingBuilder,
      showRetry = true,
      retryBuilder,
      errorBuilder})
      : assert(itemBuilder == null || itemListBuilder == null, "Cannot have both itemBuilder and itemListBuilder"),
        assert(itemBuilder != null || itemListBuilder != null, "Either itemBuilder or itemListBuilder must be specified and not equal to null"),
        super(
            key: key,
            pageSize: pageSize,
            totalCount: totalCount,
            pageFuture: pageFuture,
            padding: padding,
            controller: controller,
            primary: primary,
            shrinkWrap: shrinkWrap,
            loadingBuilder: loadingBuilder,
            showRetry: showRetry,
            retryBuilder: retryBuilder,
            errorBuilder: errorBuilder);

  @override
  Widget buildPage(BuildContext context, List page) {

    List<Widget> children = this.itemBuilder != null?
      page.map<Widget>((item) => this.itemBuilder(context, item)).toList() :
      page.expand<Widget>((item) => this.itemListBuilder(context, item)).toList();

    return ListView(
        shrinkWrap: true,
        primary: false,
        children: children
    );
  }
}
