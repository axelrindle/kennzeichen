import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:go_router/go_router.dart';
import 'package:kennzeichen/database/model.dart';
import 'package:kennzeichen/database/model/kennzeichen.dart';
import 'package:kennzeichen/widgets/KennzeichenInfo.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

class PageHome extends StatefulWidget {
  final int? activePage;

  const PageHome({super.key, this.activePage});

  @override
  State<PageHome> createState() => _PageHomeState();
}

typedef SearchCallback = void Function(Kennzeichen k);

class _Search extends SearchDelegate<Kennzeichen> {

  final List<Kennzeichen> kennzeichen;
  final SearchCallback onClick;

  _Search(this.kennzeichen, this.onClick);

  @override
  List<Widget>? buildActions(BuildContext context) {

    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
      // Exit from the search screen.
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final theme = Theme.of(context);

    final future = Model.find(Kennzeichen(), Kennzeichen.fromMap,
        where: "Kuerzel LIKE ?",
        whereArgs: ["$query%"]);

    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          List<Widget> children = [];

          if (snapshot.hasData) {
            final data = snapshot.data!;
            children = List.generate(data.length,
              (index) {
                final item = data[index];
                return ListTile(
                  onTap: () {
                    onClick(item);
                  },
                  title: RichText(text: TextSpan(
                      style: theme.textTheme.bodyLarge,
                      children: [
                        TextSpan(text: item.Kuerzel!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: ": "),
                        TextSpan(text: item.Ort ?? item.Speziell ?? ''),
                      ]
                  )),
                );
              },
            );
          } else if (snapshot.hasError) {
            children = <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              ),
            ];
          }

          return ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: children[index],
              );
            },
          );
        },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView.builder(
        itemCount: 0,
        itemBuilder: (context, index) {
          return null;
        },
      );
    }

    return buildResults(context);
  }

}

class _PageHomeState extends State<PageHome> {

  final fab = GlobalKey<ExpandableFabState>();

  final scrollController = ScrollController();
  late GridObserverController observerController;

  List<Kennzeichen> kennzeichen = [];
  List<String> states = [];

  String? filterState;

  Future<void> loadData() async {
    final kennzeichen = await Model.find(Kennzeichen(), Kennzeichen.fromMap,
      where: filterState == null ? null : "Bundesland = ?",
      whereArgs: filterState == null ? [] : [filterState]
    );
    final states = kennzeichen.map((e) => e.Bundesland ?? 'Speziell')
        .toSet()
        .toList();

    states.sort((a, b) {
      if (a == 'Speziell') {
        return 1;
      } else if (b == 'Speziell') {
        return -1;
      }

      return a.compareTo(b);
    });

    setState(() {
      this.kennzeichen = kennzeichen;

      if (this.states.isEmpty) {
        this.states = states;
      }
    });
  }

  void showSearchOverlay(BuildContext context) {
    fab.currentState?.toggle();

    showSearch(
      context: context,
      delegate: _Search(kennzeichen, (k) {
        final index = kennzeichen.indexWhere((element) => element.Kuerzel == k.Kuerzel);
        if (index > -1) {
          context.pop();
          observerController.animateTo(
            index: index,
            duration: const Duration(seconds: 2),
            curve: Curves.ease,
          );
        }
      }),
    );
  }

  void showFilterSheet(BuildContext context) {
    fab.currentState?.toggle();

    final theme = Theme.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    final items = states.map<DropdownMenuEntry<String?>>((e) => DropdownMenuEntry(
      label: e,
      value: e,
    )).toList();
    items.insert(0, const DropdownMenuEntry(value: null, label: "Alle"));

    showModalBottomSheet(
        context: context,
        builder: (context) => SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Text("Filter",
                style: theme.textTheme.headlineLarge,
              ),
              DropdownMenu(
                dropdownMenuEntries: items,
                menuHeight: 200,
                initialSelection: filterState,
                onSelected: (value) {
                  filterState = value;
                  loadData();
                },
              ),
            ],
          ),
        )
    );
  }

  void showItemInfo(BuildContext context, int index) {
    final kennzeichen = this.kennzeichen[index];

    showAdaptiveDialog(context: context, builder: (context) {
      return Dialog.fullscreen(
        child: KennzeichenInfo(kennzeichen),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    observerController = GridObserverController(controller: scrollController);

    loadData();
  }

  @override
  void deactivate() {

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(filterState ?? "Kennzeichen"),
        centerTitle: Platform.isIOS,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed("Settings"),
          )
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        key: fab,
        type: ExpandableFabType.up,
        distance: 64,
        children: [
          // Search
          FloatingActionButton.small(
            heroTag: "search",
            child: const Icon(Icons.search),
            onPressed: () => showSearchOverlay(context),
          ),
          // Filter
          FloatingActionButton.small(
            heroTag: "filter",
            child: const Icon(Icons.filter_alt),
            onPressed: () => showFilterSheet(context),
          )
        ],
      ),
      body: GridViewObserver(
        controller: observerController,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: kennzeichen.length,
          itemBuilder: (context, index) => Container(
            decoration: kennzeichen[index].Speziell == null ? null : BoxDecoration(
                color: theme.primaryColor.withAlpha(50),
                borderRadius: BorderRadius.circular(16)
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showItemInfo(context, index),
              child: Center(
                child: Text(kennzeichen[index].Kuerzel!,
                  style: theme.textTheme.headlineLarge,
                ),
              ),
            ),
          ),
          primary: false,
          padding: const EdgeInsets.all(16),
          controller: scrollController,
        ),
      ),
    );
  }

}