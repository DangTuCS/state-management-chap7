import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

enum ItemFilter {
  all,
  longtext,
  shortTexts,
}

@immutable
class State {
  final Iterable<String> items;
  final ItemFilter filter;

  const State({
    required this.items,
    required this.filter,
  });

  Iterable<String> get filteredItems {
    switch (filter) {
      case ItemFilter.all:
        return items;
      case ItemFilter.longtext:
        return items.where((element) => element.length >= 10);
      case ItemFilter.shortTexts:
        return items.where((element) => element.length <= 3);
    }
  }
}

@immutable
abstract class Action {
  const Action();
}

@immutable
class ChangeFilterTypeAction extends Action {
  final ItemFilter filter;

  const ChangeFilterTypeAction({
    required this.filter,
  });
}

@immutable
abstract class ItemAction extends Action {
  final String item;

  const ItemAction({
    required this.item,
  });
}

@immutable
class AddItemAction extends ItemAction {
  const AddItemAction({required super.item});
}

@immutable
class RemoveItemAction extends ItemAction {
  const RemoveItemAction({required super.item});
}

extension AddRemoveItems<T> on Iterable<T> {
  Iterable<T> operator +(T other) => followedBy([other]);

  Iterable<T> operator -(T other) => where((element) => element != other);
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
