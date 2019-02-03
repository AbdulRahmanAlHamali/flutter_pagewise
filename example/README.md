The example in [lib/main.dart](./lib/main.dart):

uses Pagewise to display paginated data in 4 different ways:
1. `ListView`
2. `GridView`
3. `SliverListView`
4. `SliverGridView`

All the views fetch their data from [JSON placeholder](http://jsonplaceholder.typicode.com/),
an online service that provides dummy JSON data for testing. The `ListViews` fetch the posts from
the service, while the `GridViews` fetch the images.

The service allows us to specify a `start` and `limit` parameters, which allows us to effectively
achieve pagination. The `start` parameter specifies the first element to fetch, while the `limit`
specifies the number of elements to fetch, that is, the page size.