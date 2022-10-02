import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:http/http.dart' as http;

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

const apiUrl = 'http://127.0.0.1:5500/api/people.json';

@immutable
class Person {
  final String name;
  final int age;

  const Person({required this.name, required this.age});

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        name: json['name'],
        age: json['age'],
      );

  @override
  String toString() {
    return 'Person ($name, $age years old)';
  }
}

@immutable
class Action {
  const Action();
}

@immutable
class LoadPeopleAction extends Action {
  const LoadPeopleAction();
}

@immutable
class SuccessfullyFetchedPeopleAction extends Action {
  final Iterable<Person> persons;

  const SuccessfullyFetchedPeopleAction({required this.persons});
}

@immutable
class FailedFetchedPeopleAction extends Action {
  final Object error;

  const FailedFetchedPeopleAction({required this.error});
}

@immutable
class State {
  final bool isLoading;
  final Iterable<Person>? fetchedPersons;
  final Object? error;

  const State({
    required this.isLoading,
    required this.fetchedPersons,
    required this.error,
  });

  //initial
  const State.empty()
      : isLoading = false,
        fetchedPersons = null,
        error = null;
}

State reducer(State oldState, action) {
  if (action is LoadPeopleAction) {
    return const State(
      error: null,
      fetchedPersons: null,
      isLoading: true,
    );
  } else if (action is SuccessfullyFetchedPeopleAction) {
    return State(
      error: null,
      fetchedPersons: action.persons,
      isLoading: false,
    );
  } else if (action is FailedFetchedPeopleAction) {
    return State(
      error: action.error,
      fetchedPersons: oldState.fetchedPersons,
      isLoading: false,
    );
  }
  return oldState;
}

void loadPeopleMiddleware(
  Store<State> store,
  action,
  NextDispatcher next,
) {
  if (action is LoadPeopleAction) {
    getPersons().then((persons) {

      store.dispatch(SuccessfullyFetchedPeopleAction(persons: persons));
    }).catchError((e) {
      store.dispatch(FailedFetchedPeopleAction(error: e));
    });
  }
  next(action);
}

Future<Iterable<Person>> getPersons() => HttpClient()
    .getUrl(Uri.parse(apiUrl))
    .then((req) => req.close())
    .then((resp) => resp.transform(utf8.decoder).join())
    .then((str) => json.decode(str) as List<dynamic>)
    .then((list) => list.map((e) => Person.fromJson(e)));

// Future<Iterable<Person>> getPersons() async {
//   print('access');
//   final response = await http.get(Uri.parse(apiUrl));
//   final people = json.decode(response.body) as List<dynamic>;
//   print(people.map((e) => Person.fromJson(e)));
//   return people.map((e) => Person.fromJson(e));
// }

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = Store(
      reducer,
      initialState: const State.empty(),
      middleware: [loadPeopleMiddleware],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Pages'),
      ),
      body: StoreProvider(
        store: store,
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                store.dispatch(const LoadPeopleAction());
                print(1);
              },
              child: const Text('Load Persons'),
            ),
            StoreConnector<State, bool>(
              builder: (context, isLoading) {
                if (isLoading) {
                  print('loading');
                  return const CircularProgressIndicator();
                } else {
                  return const SizedBox();
                }
              },
              converter: (store) => store.state.isLoading,
            ),
            StoreConnector<State, Iterable<Person>?>(
              builder: (context, people) {
                if (people == null) {
                  print('people = null');
                  return const SizedBox();
                } else {
                  return Expanded(
                    child: ListView.builder(
                      itemBuilder: (context, index) {
                        final person = people.elementAt(index);
                        return ListTile(
                          title: Text(
                            person.toString(),
                          ),
                        );
                      },
                      itemCount: people.length,
                    ),
                  );
                }
              },
              converter: (store) => store.state.fetchedPersons,
            ),
          ],
        ),
      ),
    );
  }
}
