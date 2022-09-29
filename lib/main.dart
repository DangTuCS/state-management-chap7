import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart' as hooks;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

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

Iterable<String> addItemReducer(
  Iterable<String> previousItems,
  AddItemAction action,
) =>
    previousItems + action.item;

Iterable<String> removeItemReducer(
  Iterable<String> previousItems,
  RemoveItemAction action,
) =>
    previousItems - action.item;

Reducer<Iterable<String>> itemsReducer = combineReducers<Iterable<String>>([
  TypedReducer<Iterable<String>, AddItemAction>(addItemReducer),
  TypedReducer<Iterable<String>, RemoveItemAction>(removeItemReducer),
]);

ItemFilter itemFilterReducer(
  State oldState,
  Action action,
) {
  if (action is ChangeFilterTypeAction) {
    return action.filter;
  } else {
    return oldState.filter;
  }
}

State appStateReducer(State oldState, action) => State(
      items: itemsReducer(oldState.items, action),
      filter: itemFilterReducer(oldState, action),
    );

class MyHomePage extends hooks.HookWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Store(
      appStateReducer,
      initialState: const State(items: [], filter: ItemFilter.all),
    );
    final controller = hooks.useTextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: StoreProvider(
        store: store,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => store.dispatch(
                      const ChangeFilterTypeAction(filter: ItemFilter.all),
                    ),
                    child: const Text('All'),
                  ),
                  TextButton(
                    onPressed: () => store.dispatch(
                      const ChangeFilterTypeAction(
                          filter: ItemFilter.shortTexts),
                    ),
                    child: const Text('Short items'),
                  ),
                  TextButton(
                    onPressed: () => store.dispatch(
                      const ChangeFilterTypeAction(filter: ItemFilter.longtext),
                    ),
                    child: const Text('Long items'),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: controller,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final text = controller.text;
                      store.dispatch(
                        AddItemAction(item: text),
                      );
                      controller.clear();
                    },
                    child: const Text('Add'),
                  ),
                  TextButton(
                    onPressed: () {
                      final text = controller.text;
                      store.dispatch(
                        RemoveItemAction(item: text),
                      );
                      controller.clear();
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
              StoreConnector<State, Iterable<String>>(
                builder: (context, items) {
                  return Expanded(
                    child: ListView.builder(itemBuilder: (context,index){
                      final item = items.elementAt(index);
                      return Text(item);
                    },itemCount: items.length,),
                  );
                },
                converter: (store) => store.state.filteredItems,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
