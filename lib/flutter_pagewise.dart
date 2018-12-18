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

  /// The controller that controls the loading of pages.
  ///
  /// You don't have to provide this parameter unless you want to control or
  /// listen to the data that Pagewise fetches. Review the documentation of
  /// [PagewiseLoadController] for more details
  final PagewiseLoadController controller;

  /// Creates a pagewise widget.
  ///
  /// This is an abstract class, this constructor should only be called from
  /// constructors of widgets that extend this class
  Pagewise(
      {this.pageSize,
      this.pageFuture,
      Key key,
      this.controller,
      this.loadingBuilder,
      this.retryBuilder,
      this.showRetry: true,
      @required this.itemBuilder,
      this.errorBuilder,
      @required this.builder})
      : assert(showRetry != null),
        assert((controller == null && pageSize != null && pageFuture != null) ||
            (controller != null && pageSize == null && pageFuture == null)),
        assert(showRetry == false || errorBuilder == null,
            'Cannot specify showRetry and errorBuilder at the same time'),
        assert(showRetry == true || retryBuilder == null,
            "Cannot specify retryBuilder when showRetry is set to false"),
        super(key: key);

  @override
  PagewiseState createState() => PagewiseState();
}

class PagewiseState extends State<Pagewise> {
  PagewiseLoadController _controller;

  PagewiseLoadController get _effectiveController =>
      widget.controller ?? this._controller;

  VoidCallback _controllerListener;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      this._controller = PagewiseLoadController(
          pageFuture: widget.pageFuture, pageSize: widget.pageSize);
    }

    this._effectiveController.init();

    this._controllerListener = () {
      setState(() {});
    };

    this._effectiveController.addListener(this._controllerListener);
  }

  @override
  void dispose() {
    super.dispose();
    this._effectiveController.removeListener(this._controllerListener);
  }

  @override
  void didUpdateWidget(Pagewise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      oldWidget.controller.removeListener(this._controllerListener);
      this._controller = PagewiseLoadController(
          pageFuture: oldWidget.controller.pageFuture,
          pageSize: oldWidget.controller.pageSize);
      this._effectiveController.addListener(this._controllerListener);
      this._effectiveController.init();
    } else if (widget.controller != null && oldWidget.controller == null) {
      this._controller.removeListener(this._controllerListener);
      this._controller = null;
      this._effectiveController.addListener(this._controllerListener);
      this._effectiveController.init();
    } else if (widget.controller != null &&
        (widget.controller != oldWidget.controller)) {
      oldWidget.controller.removeListener(this._controllerListener);
      this._effectiveController.addListener(this._controllerListener);
      this._effectiveController.init();
    }
  }

  int get _itemCount => this._effectiveController.loadedItems.length + 1;

  @override
  Widget build(BuildContext context) {
    return widget.builder(this);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index > this._effectiveController.loadedItems.length) return null;

    if (index == this._effectiveController.loadedItems.length) {
      if (this._effectiveController.error != null) {
        if (widget.showRetry) {
          return this._getRetryWidget();
        } else {
          return this._getErrorWidget(this._effectiveController.error);
        }
      }

      if (this._effectiveController.hasMoreItems) {
        this._effectiveController.fetchNewPage();
        return this._getLoadingWidget();
      } else {
        return Container();
      }
    } else {
      return widget.itemBuilder(
          context, this._effectiveController.loadedItems[index], index);
    }
  }

  Widget _getLoadingWidget() {
    return this._getStandardContainer(
        child: widget.loadingBuilder != null
            ? widget.loadingBuilder(context)
            : CircularProgressIndicator());
  }

  Widget _getErrorWidget(Object error) {
    return this._getStandardContainer(
        child: widget.errorBuilder != null
            ? widget.errorBuilder(context, this._effectiveController.error)
            : Text('Error: $error',
                style: TextStyle(
                    color: Theme.of(context).disabledColor,
                    fontStyle: FontStyle.italic)));
  }

  Widget _getRetryWidget() {
    var defaultRetryButton = FlatButton(
      child: Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      color: Colors.grey[300],
      shape: CircleBorder(),
      onPressed: this._effectiveController.retry,
    );

    return this._getStandardContainer(
        child: widget.retryBuilder != null
            ? widget.retryBuilder(context, this._effectiveController.retry)
            : defaultRetryButton);
  }

  Widget _getStandardContainer({Widget child}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: child,
        ));
  }
}

/// The controller responsible for managing page loading in Pagewise
///
/// You don't have to provide a controller yourself when creating a Pagewise
/// widget. The widget will create one for you. However you might wish to create
/// one yourself in order to achieve some effects.
///
/// Notice though that if you provide a controller yourself, you should provide
/// the [pageFuture] and [pageSize] parameters to the *controller* instead of
/// the widget.
///
/// A possible use case of the controller is to force a reset of the loaded
/// pages using a [RefreshIndicator](https://docs.flutter.io/flutter/material/RefreshIndicator-class.html).
/// you could achieve that as follows:
///
/// ```dart
/// final _pageLoadController = PagewiseLoadController(
///   pageSize: 6,
///   pageFuture: BackendService.getPage
/// );
///
/// @override
/// Widget build(BuildContext context) {
///   return RefreshIndicator(
///     onRefresh: () async {
///       await this._pageLoadController.reset();
///     },
///     child: PagewiseListView(
///         itemBuilder: this._itemBuilder,
///         pageLoadController: this._pageLoadController,
///     ),
///   );
/// }
/// ```
///
/// Another use case for creating the controller yourself is if you want to
/// listen to the state of Pagewise and act accordingly.
/// For example, you might want to show a specific widget when the list is empty
/// In that case, you could do:
/// ```dart
/// final _pageLoadController = PagewiseLoadController(
///   pageSize: 6,
///   pageFuture: BackendService.getPage
/// );
///
/// bool _empty = false;
///
/// @override
/// void initState() {
///   super.initState();
///
///   this._pageLoadController.addListener(() {
///     if (this._pageLoadController.noItemsFound) {
///       setState(() {
///         this._empty = this._pageLoadController.noItemsFound;
///       });
///     }
///   });
/// }
/// ```
///
/// And then in your `build` function you do:
/// ```dart
/// if (this._empty) {
///   return Text('NO ITEMS FOUND');
/// }
/// ```
class PagewiseLoadController<T> extends ChangeNotifier {
  List<T> _loadedItems;
  int _numberOfLoadedPages;
  bool _hasMoreItems;
  Object _error;

  /// Called whenever a new page (or batch) is to be fetched
  ///
  /// It is provided with the page index, and expected to return a [Future](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) that
  /// resolves to a list of entries. Please make sure to return only [pageSize]
  /// or less entries (in the case of the last page) for each page.
  final PageFuture pageFuture;

  /// The number  of entries per page
  final int pageSize;

  /// Creates a PagewiseLoadController.
  ///
  /// You must provide both the [pageFuture] and the [pageSize]
  PagewiseLoadController({@required this.pageFuture, @required this.pageSize});

  /// The list of items that have already been loaded
  List<T> get loadedItems => this._loadedItems;

  /// The number of pages that have already been loaded
  int get numberOfLoadedPages => this._numberOfLoadedPages;

  /// Whether there are still more items to load
  bool get hasMoreItems => this._hasMoreItems;

  /// The latest error that has been faced when trying to load a page
  Object get error => this._error;

  /// set to true if no data was found
  bool get noItemsFound =>
      this._loadedItems.length == 0 && this.hasMoreItems == false;

  /// Called to initialize the controller. Same as [reset]
  init() {
    this.reset();
  }

  /// Resets all the information of the controller
  reset() {
    this._loadedItems = [];
    this._numberOfLoadedPages = 0;
    this._hasMoreItems = true;
    this._error = null;
    this.notifyListeners();
  }

  /// Fetches a new page by calling [pageFuture]
  Future<void> fetchNewPage() async {
    List<T> page;
    try {
      page = await this.pageFuture(this._numberOfLoadedPages);
      this._numberOfLoadedPages++;
    } catch (error) {
      this._error = error;
      this.notifyListeners();
      return;
    }

    if (page.length > this.pageSize) {
      throw ('Page length (${page.length}) is greater than the maximum size (${this.pageSize})');
    }

    if (page.length == 0) {
      this._hasMoreItems = false;
    } else {
      this._loadedItems.addAll(page);
    }
    notifyListeners();
  }

  /// Attempts to retry in case an error occurred
  retry() {
    this._error = null;
    this.notifyListeners();
  }
}

class PagewiseListView extends Pagewise {
  /// Creates a Pagewise ListView.
  ///
  /// All the properties are those of normal [ListViews](https://docs.flutter.io/flutter/widgets/ListView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseListView(
      {Key key,
      padding,
      primary,
      addSemanticIndexes = true,
      semanticChildCount,
      shrinkWrap: false,
      controller,
      pageLoadController,
      itemExtent,
      addAutomaticKeepAlives: true,
      scrollDirection: Axis.vertical,
      addRepaintBoundaries: true,
      cacheExtent,
      physics,
      reverse: false,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
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
                  itemBuilder: state._itemBuilder);
            });
}

class PagewiseGridView extends Pagewise {
  /// Creates a Pagewise GridView with a crossAxisCount.
  ///
  /// All the properties are those of normal [GridViews](https://docs.flutter.io/flutter/widgets/GridView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseGridView.count(
      {Key key,
      padding,
      @required crossAxisCount,
      childAspectRatio,
      crossAxisSpacing,
      mainAxisSpacing,
      addSemanticIndexes = true,
      semanticChildCount,
      primary,
      shrinkWrap: false,
      controller,
      pageLoadController,
      addAutomaticKeepAlives: true,
      scrollDirection: Axis.vertical,
      addRepaintBoundaries: true,
      cacheExtent,
      physics,
      reverse: false,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
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
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCountAndLoading(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: mainAxisSpacing,
                          itemCount: state._itemCount),
                  itemCount: state._itemCount,
                  itemBuilder: state._itemBuilder);
            });

  /// Creates a Pagewise GridView with a maxCrossAxisExtent.
  ///
  /// All the properties are those of normal [GridViews](https://docs.flutter.io/flutter/widgets/GridView-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseGridView.extent(
      {Key key,
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
      pageLoadController,
      addAutomaticKeepAlives: true,
      scrollDirection: Axis.vertical,
      addRepaintBoundaries: true,
      cacheExtent,
      physics,
      reverse: false,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
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
                  gridDelegate:
                      SliverGridDelegateWithMaxCrossAxisExtentAndLoading(
                          maxCrossAxisExtent: maxCrossAxisExtent,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: crossAxisSpacing,
                          mainAxisSpacing: mainAxisSpacing,
                          itemCount: state._itemCount),
                  itemCount: state._itemCount,
                  itemBuilder: state._itemBuilder);
            });
}

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

class PagewiseSliverList extends Pagewise {
  /// Creates a Pagewise SliverList.
  ///
  /// All the properties are those of normal [SliverList](https://docs.flutter.io/flutter/widgets/SliverList-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseSliverList(
      {Key key,
      addSemanticIndexes = true,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      semanticIndexCallback = _kDefaultSemanticIndexCallback,
      semanticIndexOffset = 0,
      pageLoadController,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
            key: key,
            loadingBuilder: loadingBuilder,
            retryBuilder: retryBuilder,
            showRetry: showRetry,
            itemBuilder: itemBuilder,
            errorBuilder: errorBuilder,
            builder: (state) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(state._itemBuilder,
                    addAutomaticKeepAlives: addAutomaticKeepAlives,
                    addRepaintBoundaries: addRepaintBoundaries,
                    addSemanticIndexes: addSemanticIndexes,
                    semanticIndexCallback: semanticIndexCallback,
                    semanticIndexOffset: semanticIndexOffset,
                    childCount: state._itemCount),
              );
            });
}

class PagewiseSliverGrid extends Pagewise {
  /// Creates a Pagewise SliverGrid with a crossAxisCount.
  ///
  /// All the properties are those of normal [SliverGrid](https://docs.flutter.io/flutter/widgets/SliverGrid-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseSliverGrid.count(
      {Key key,
      addSemanticIndexes = true,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      semanticIndexCallback = _kDefaultSemanticIndexCallback,
      semanticIndexOffset = 0,
      @required crossAxisCount,
      childAspectRatio,
      crossAxisSpacing,
      mainAxisSpacing,
      pageLoadController,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
            key: key,
            loadingBuilder: loadingBuilder,
            retryBuilder: retryBuilder,
            showRetry: showRetry,
            itemBuilder: itemBuilder,
            errorBuilder: errorBuilder,
            builder: (state) {
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(state._itemBuilder,
                    addAutomaticKeepAlives: addAutomaticKeepAlives,
                    addRepaintBoundaries: addRepaintBoundaries,
                    addSemanticIndexes: addSemanticIndexes,
                    semanticIndexCallback: semanticIndexCallback,
                    semanticIndexOffset: semanticIndexOffset,
                    childCount: state._itemCount),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCountAndLoading(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                        itemCount: state._itemCount),
              );
            });

  /// Creates a Pagewise SliverGrid with a maxCrossAxisExtent.
  ///
  /// All the properties are those of normal [SliverGrid](https://docs.flutter.io/flutter/widgets/SliverGrid-class.html)
  /// except [pageSize], [pageFuture], [loadingBuilder], [retryBuilder],
  /// [showRetry], [itemBuilder] and [errorBuilder]
  PagewiseSliverGrid.extent(
      {Key key,
      addSemanticIndexes = true,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      semanticIndexCallback = _kDefaultSemanticIndexCallback,
      semanticIndexOffset = 0,
      @required maxCrossAxisExtent,
      childAspectRatio,
      crossAxisSpacing,
      mainAxisSpacing,
      pageLoadController,
      pageSize,
      pageFuture,
      loadingBuilder,
      retryBuilder,
      showRetry: true,
      @required itemBuilder,
      errorBuilder})
      : super(
            pageSize: pageSize,
            pageFuture: pageFuture,
            controller: pageLoadController,
            key: key,
            loadingBuilder: loadingBuilder,
            retryBuilder: retryBuilder,
            showRetry: showRetry,
            itemBuilder: itemBuilder,
            errorBuilder: errorBuilder,
            builder: (state) {
              return SliverGrid(
                delegate: SliverChildBuilderDelegate(state._itemBuilder,
                    addAutomaticKeepAlives: addAutomaticKeepAlives,
                    addRepaintBoundaries: addRepaintBoundaries,
                    addSemanticIndexes: addSemanticIndexes,
                    semanticIndexCallback: semanticIndexCallback,
                    semanticIndexOffset: semanticIndexOffset,
                    childCount: state._itemCount),
                gridDelegate:
                    SliverGridDelegateWithMaxCrossAxisExtentAndLoading(
                        maxCrossAxisExtent: maxCrossAxisExtent,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: crossAxisSpacing,
                        mainAxisSpacing: mainAxisSpacing,
                        itemCount: state._itemCount),
              );
            });
}
