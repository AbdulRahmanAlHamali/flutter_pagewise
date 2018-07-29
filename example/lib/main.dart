import 'dart:async';
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
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'PagewiseGridView',
              ),
              Tab(
                text: 'PagewiseListView'
              )
            ]
          ),
        ),
        body: TabBarView(
          children: [
            PagewiseGridViewExample(),
            PagewiseListViewExample()
          ],
        )
      ),
    );
  }
}

class PagewiseGridViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PagewiseGridView(
      pageSize: 10,
      totalCount: 40,
      crossAxisCount: 2,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      childAspectRatio: 0.555,
      padding: EdgeInsets.all(15.0),
      itemBuilder: (context, entry) {
        return Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: Border.all(),
            ),
            child: Column(
              children: [
                Text(entry['name']),
                Text('\$' + entry['price'].toString())
              ]
            )
        );
      },
      pageFuture: BackendService.getPage,
    );
  }
}

class PagewiseListViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PagewiseListView(
      pageSize: 10,
      totalCount: 40,
      padding: EdgeInsets.all(15.0),
      itemBuilder: (BuildContext context, entry) {
        return Column(
          children: [
            ListTile(
              title: Text(entry['name']),
              subtitle: Text('\$' + entry['price'].toString()),
            ),
            Divider()
          ]
        );
      },
      pageFuture: BackendService.getPage
    );
  }
}

class BackendService {
  static Future<List> getPage(pageIndex) async {
    int size = 10;
    var rng = Random();
    List list = List.generate(size, (index) {
      int dataNumber = index + pageIndex * size;
      return {
        'name': 'product' + dataNumber.toString(),
        'price': rng.nextInt(100)
      };
    });
    await Future.delayed(Duration(seconds: pageIndex == 1? 5 : 2));
    return list;
  }
}