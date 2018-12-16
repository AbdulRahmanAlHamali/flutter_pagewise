import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Pagewise Demo',
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(tabs: [
              Tab(
                text: 'PagewiseListView',
              ),
              Tab(text: 'PagewiseGridView')
            ]),
          ),
          body: TabBarView(
            children: [PagewiseListViewExample(), PagewiseGridViewExample()],
          )),
    );
  }
}

class PagewiseGridViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PagewiseGridView.count(
      pageSize: 6,
      crossAxisCount: 3,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      childAspectRatio: 0.555,
      padding: EdgeInsets.all(15.0),
      itemBuilder: this._itemBuilder,
      pageFuture: BackendService.getPage,
    );
  }

  Widget _itemBuilder(context, entry, _) {
    return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[600]),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      image: DecorationImage(
                          image: AssetImage('assets/images/flutter.png'),
                          fit: BoxFit.fill)),
                ),
              ),
              SizedBox(height: 8.0),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(entry['name'], style: TextStyle(fontSize: 18.0))),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '\$' + entry['price'].toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8.0)
            ]));
  }
}

class PagewiseListViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PagewiseListView(
        pageSize: 6,
        itemBuilder: this._itemBuilder,
        pageFuture: BackendService.getPage);
  }

  Widget _itemBuilder(context, entry, _) {
    return ListTile(
      leading: Icon(
        Icons.shopping_cart,
        color: Colors.brown[200],
      ),
      title: Text(entry['name']),
      subtitle: Text('\$' + entry['price'].toString()),
    );
  }
}

class BackendService {
  static Future<List> getPage(pageIndex) async {
    await Future.delayed(Duration(seconds: 1));

    if (pageIndex == 3 && Random().nextInt(10) < 7) {
      throw 'I am an exception!';
    }

    int size = 6;
    var rng = Random();

    if (pageIndex == 7) {
      return [];
    }

    List list = List.generate(pageIndex < 6 ? size : 5, (index) {
      int dataNumber = index + pageIndex * size;
      return {
        'name': 'product' + dataNumber.toString(),
        'price': rng.nextInt(100)
      };
    });
    return list;
  }
}
