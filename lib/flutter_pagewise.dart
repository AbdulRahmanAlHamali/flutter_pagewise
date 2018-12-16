/// A library for widgets that load their content one page (or batch) at a time (also known as lazy-loading).
///
/// ## Features
/// * Load data one page at a time
/// * Retry failed pages
/// * Override the default loading, retry, and error widgets if desired
/// * ListView and GridView implementations
/// * Extendability using inheritance
///
/// ## Breaking Change Starting V1.0.0:
/// The library has been rewritten in version 1.0.0 to provide a more
/// efficient implementation that does not require a `totalCount` parameter
/// and shows only one loading sign when users scroll down. In addition,
/// a new parameter has been added to `itemBuilder` callback to provide
/// the index if needed by the user.
///
/// ## Installing the library:
///
/// Like any other package, add the library to your pubspec.yaml dependencies:
/// ```
/// dependencies:
//    flutter_pagewise:
/// ```
/// Then import it wherever you want to use it:
/// ```
/// import 'package:flutter_pagewise/flutter_pagewise.dart';
/// ```
///
/// ## Using the library
/// The library provides two main widgets:
///  * [PagewiseGridView]: A pagewise implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html). It could be
///  used as follows:
///  ```dart
///  PagewiseGridView.count(
///    pageSize: 10,
///    crossAxisCount: 2,
///    mainAxisSpacing: 8.0,
///    crossAxisSpacing: 8.0,
///    childAspectRatio: 0.555,
///    padding: EdgeInsets.all(15.0),
///    itemBuilder: (context, entry, index) {
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
///    padding: EdgeInsets.all(15.0),
///    itemBuilder: (context, entry, index) {
///      // return a widget that displays the entry's data
///    },
///    pageFuture: (pageIndex) {
///      // return a Future that resolves to a list containing the page's data
///    }
///  );
///  ```
///
/// The classes provide all the properties of `ListViews` and
/// `GridViews`. In addition, you must provide the [Pagewise.itemBuilder], which
/// tells Pagewise how you want to render each element, and [Pagewise.pageFuture],
/// which Pagewise calls to fetch new pages. Please note that `pageFuture`
/// must not return more values than mentioned in the [Pagewise.pageSize] parameter.
///
/// ## Customizing the widget:
/// In addition to the required parameters, Pagewise provides you with
/// optional parameters to customize the widget. You have [Pagewise.loadingBuilder],
/// [Pagewise.errorBuilder], and [Pagewise.retryBuilder] to customize the widgets that show
/// on loading, error, and retry respectively.
///
/// The `loadingBuilder` can be used as follows:
/// ```
/// loadingBuilder: (context) {
///   return Text('Loading...');
/// }
/// ```
///
/// The `retryBuilder` can be used as follows:
/// ```
/// retryBuilder: (context, callback) {
///   return RaisedButton(
///     child: Text('Retry'),
///     onPressed: () => callback()
///   );
/// }
/// ```
/// Thus, the `retryBuilder` provides you with a callback that you can
/// call when you want to retry.
///
/// The `errorBuilder` is only relevant when `showRetry` is set to `false`,
/// because, otherwise, the `retryBuilder` is shown instead. The `errorBuilder`
/// can be used as follows:
/// ```
/// errorBuilder: (context, error) {
///   return Text('Error: $error');
/// }
/// ```
///
/// Check the classes' documentation for more details.
///
/// ## Creating your own Pagewise Widgets:
/// You need to inherit from the [Pagewise] class. Check the code of
/// [PagewiseListView] and [PagewiseGridView] for examples
library flutter_pagewise;

import 'package:flutter/material.dart';
import 'package:flutter_pagewise/helpers/grid_helpers.dart';

typedef Widget ItemBuilder<T>(BuildContext context, T entry, int index);
typedef Future<List> PageFuture(int pageIndex);
typedef Widget ErrorBuilder(BuildContext context, Object error);
typedef Widget LoadingBuilder(BuildContext context);
typedef Widget RetryBuilder(BuildContext context, RetryCallback retryCallback);
typedef void RetryCallback();
typedef PagewiseBuilder(PagewiseState state);

/// An abstract base class for widgets that fetch their content one page at a
/// time.
///
/// The widget fetches the page when we scroll down to it, and then keeps it in
/// memory
///
/// You can build your own Pagewise widgets by extending this class and
/// returning your builder in the [builder] function which provides you with the
/// Pagewise state. Look [PagewiseListView] and [PagewiseGridView] for examples.
///
/// See also:
///
///  * [PagewiseGridView], a [Pagewise] implementation of [GridView](https://docs.flutter.io/flutter/widgets/GridView-class.html)
///  * [PagewiseListView], a [Pagewise] implementation of [ListView](https://docs.flutter.io/flutter/widgets/ListView-class.html)
abstract class Pagewise extends StatefulWidget {

  /// The number  of entries per page
  final int pageSize;

  /// Called whenever a new page (or batch) is to be fetched
  ///
  /// It is provided with the page index, and expected to return a [Future](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) that
  /// resolves to a list of entries. Please make sure to return only [pageSize]
  /// or less entries (in the case of the last page) for each page.
  final PageFuture pageFuture;

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

  /// Called to build each entry in the view.
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

  /// The actual builder that builds the Pagewise widget. It is called and
  /// provided the PagewiseState. This function is important only for classes
  /// extending Pagewise. See [PagewiseListView] and [PagewiseGridView] for
  /// examples.
  final PagewiseBuilder builder;

  /// Creates a pagewise widget.
  ///
  /// This is an abstract class, this constructor should only be called from
  /// constructors of widgets that extend this class
  Pagewise(
      {@ required this.pageSize,
        @required this.pageFuture,
        Key key,
        this.loadingBuilder,
        this.retryBuilder,
        this.showRetry: true,
        @required this.itemBuilder,
        this.errorBuilder,
        @required this.builder
      })
      : assert(showRetry != null),
        assert(showRetry == false || errorBuilder == null,
        'Cannot specify showRetry and errorBuilder at the same time'),
        assert(showRetry == true || retryBuilder == null,
        "Cannot specify retryBuilder when showRetry is set to false"),
        super(key: key);

  @override PagewiseState createState() => PagewiseState();
}

class PagewiseState extends State<Pagewise> {

  List _loadedItems;
  int _loadedPages;
  bool _hasMoreItems;
  Object _error;

  @override
  void initState() {
    super.initState();
    this._loadedItems = [];
    this._loadedPages = 0;
    this._hasMoreItems = true;
  }

  Future<void> _fetchNewPage() async {
    List page;
    try {
      page = await widget.pageFuture(this._loadedPages);
      this._loadedPages++;
    } catch(error) {
      if (this.mounted) {
        setState(() {
          this._error = error;
        });
      }
      return;
    }

    if (this.mounted) {
      setState(() {
        if (page.length == 0) {
          this._hasMoreItems = false;
        } else {
          this._loadedItems.addAll(page);
        }
      });
    }
  }

  int get _itemCount => this._loadedItems.length + 1;

  @override
  Widget build(BuildContext context) {
    return widget.builder(this);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index == this._loadedItems.length) {

      if (this._error != null) {
        if (widget.showRetry) {
          return this._getRetryWidget();
        } else {
          return this._getErrorWidget(this._error);
        }
      }

      if (this._hasMoreItems) {
        this._fetchNewPage();
        return this._getLoadingWidget();
      } else {
        return Container();
      }
    } else {
      return widget.itemBuilder(context, this._loadedItems[index], index);
    }
  }

  Widget _getLoadingWidget() {
    return this._getStandardContainer(
      child: widget.loadingBuilder != null
          ? widget.loadingBuilder(context)
          : CircularProgressIndicator()
    );
  }

  Widget _getErrorWidget(Object error) {
    return this._getStandardContainer(
      child: widget.errorBuilder != null
        ? widget.errorBuilder(context, this._error)
        : Text(
          'Error: $error',
          style: TextStyle(
            color: Theme.of(context).disabledColor,
            fontStyle: FontStyle.italic
          )
        )
    );
  }

  Widget _getRetryWidget() {
    var defaultRetryButton = FlatButton(
      child: Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      color: Colors.grey[300],
      shape: CircleBorder(),
      onPressed: this._retry,
    );

    return this._getStandardContainer(
      child: widget.retryBuilder != null
          ? widget.retryBuilder(context, this._retry)
          : defaultRetryButton
    );

  }
  
  Widget _getStandardContainer({Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: child,
      )
    );
  }

  void _retry() {
    setState(() {
      this._error = null;
    });
  }
}

class PagewiseListView extends Pagewise {

  /// Creates a Pagewise ListView.
  ///
  /// All the properties are those of normal [ListViews](https://docs.flutter.io/flutter/widgets/ListView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseListView({
    Key key,
    padding,
    primary,
    addSemanticIndexes = true,
    semanticChildCount,
    shrinkWrap: false,
    controller,
    itemExtent,
    addAutomaticKeepAlives: true,
    scrollDirection: Axis.vertical,
    addRepaintBoundaries: true,
    cacheExtent,
    physics,
    reverse: false,
    @required pageSize,
    @required pageFuture,
    loadingBuilder,
    retryBuilder,
    showRetry: true,
    @required itemBuilder,
    errorBuilder
  }):
      super(
        pageSize: pageSize,
        pageFuture: pageFuture,
        key: key,
        loadingBuilder: loadingBuilder,
        retryBuilder: retryBuilder,
        showRetry: showRetry,
        itemBuilder: itemBuilder,
        errorBuilder: errorBuilder,
        builder: (state) {
          return ListView.builder(
            itemExtent: itemExtent,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            scrollDirection: scrollDirection,
            addRepaintBoundaries: addRepaintBoundaries,
            cacheExtent: cacheExtent,
            physics: physics,
            reverse: reverse,
            padding: padding,
            addSemanticIndexes: addSemanticIndexes,
            semanticChildCount: semanticChildCount,
            shrinkWrap: shrinkWrap,
            primary: primary,
            controller: controller,
            itemCount: state._itemCount,
            itemBuilder: state._itemBuilder
          );
        }
      );

}

class PagewiseGridView extends Pagewise {

  /// Creates a Pagewise GridView with a crossAxisCount.
  ///
  /// All the properties are those of normal [GridViews](https://docs.flutter.io/flutter/widgets/GridView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseGridView.count({
    Key key,
    padding,
    crossAxisCount,
    childAspectRatio,
    crossAxisSpacing,
    mainAxisSpacing,
    addSemanticIndexes = true,
    semanticChildCount,
    primary,
    shrinkWrap: false,
    controller,
    addAutomaticKeepAlives: true,
    scrollDirection: Axis.vertical,
    addRepaintBoundaries: true,
    cacheExtent,
    physics,
    reverse: false,
    @required pageSize,
    @required pageFuture,
    loadingBuilder,
    retryBuilder,
    showRetry: true,
    @required itemBuilder,
    errorBuilder
  }):
        super(
          pageSize: pageSize,
          pageFuture: pageFuture,
          key: key,
          loadingBuilder: loadingBuilder,
          retryBuilder: retryBuilder,
          showRetry: showRetry,
          itemBuilder: itemBuilder,
          errorBuilder: errorBuilder,
          builder: (state) {

            return GridView.builder(
              reverse: reverse,
              physics: physics,
              cacheExtent: cacheExtent,
              addRepaintBoundaries: addRepaintBoundaries,
              scrollDirection: scrollDirection,
              addAutomaticKeepAlives: addAutomaticKeepAlives,
              controller: controller,
              primary: primary,
              shrinkWrap: shrinkWrap,
              padding: padding,
              addSemanticIndexes: addSemanticIndexes,
              semanticChildCount: semanticChildCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndLoading(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                itemCount: state._itemCount
              ),
              itemCount: state._itemCount,
              itemBuilder: state._itemBuilder
            );
          }
      );

  /// Creates a Pagewise GridView with a maxCrossAxisExtent.
  ///
  /// All the properties are those of normal [GridViews](https://docs.flutter.io/flutter/widgets/GridView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseGridView.extent({
    Key key,
    padding,
    @required double maxCrossAxisExtent,
    childAspectRatio,
    crossAxisSpacing,
    mainAxisSpacing,
    addSemanticIndexes = true,
    semanticChildCount,
    primary,
    shrinkWrap: false,
    controller,
    addAutomaticKeepAlives: true,
    scrollDirection: Axis.vertical,
    addRepaintBoundaries: true,
    cacheExtent,
    physics,
    reverse: false,
    @required pageSize,
    @required pageFuture,
    loadingBuilder,
    retryBuilder,
    showRetry: true,
    @required itemBuilder,
    errorBuilder
  }):
        super(
          pageSize: pageSize,
          pageFuture: pageFuture,
          key: key,
          loadingBuilder: loadingBuilder,
          retryBuilder: retryBuilder,
          showRetry: showRetry,
          itemBuilder: itemBuilder,
          errorBuilder: errorBuilder,
          builder: (state) {

            return GridView.builder(
                reverse: reverse,
                physics: physics,
                cacheExtent: cacheExtent,
                addRepaintBoundaries: addRepaintBoundaries,
                scrollDirection: scrollDirection,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addSemanticIndexes: addSemanticIndexes,
                semanticChildCount: semanticChildCount,
                controller: controller,
                primary: primary,
                shrinkWrap: shrinkWrap,
                padding: padding,
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtentAndLoading(
                    maxCrossAxisExtent: maxCrossAxisExtent,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    itemCount: state._itemCount
                ),
                itemCount: state._itemCount,
                itemBuilder: state._itemBuilder
            );
          }
      );
}
