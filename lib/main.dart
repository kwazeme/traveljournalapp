import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}
// the journal model for data entry
class JournalEntry {
  final String text;
  final String imagePath;
  JournalEntry({required this.text, required this.imagePath});
}
// app entry point iniitlialisation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAppState(),
      child: MaterialApp(
        title: 'Travel Journal',
        theme: ThemeData(
          // choose theme wide color scheme
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var entries = <JournalEntry>[];
  JournalEntry? currentEntry;
// save the Journal entries
  void saveEntry(String text, String imagePath) {
    final entry = JournalEntry(text: text, imagePath: imagePath);
    entries.add(entry);
    currentEntry = entry;
    notifyListeners();
  }
// set current selected entry for viewing and editing
  void setCurrentEntry(JournalEntry? entry) {
    currentEntry = entry;
    notifyListeners();
  }
  // method to edit and Save currentEntry in place
  void editEntry(JournalEntry entry, String newText, String newImagePath) {
    final index = entries.indexOf(entry);
    if (index != -1) {
      // Replace the old entry with the new one
      entries[index] = JournalEntry(text: newText, imagePath: newImagePath);
      currentEntry = entries[index];
      notifyListeners();
    }
  }
  // delete entry method
  void deleteEntry(JournalEntry entry) {
    entries.remove(entry);
    if (currentEntry == entry) {
      currentEntry = null;
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0; // side menu selector initialiser

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = JournalPage();
        break;
      case 1:
        page = JournalListPage();
        break;
      default:
        page = Center(child: Text('No page for index $selectedIndex'));
    }
    // Responsive layoutBuilder 
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold( // use safeArea to ensure screen area for app display is not overlapping screen status bar
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  // add menu title to respond to screen size
                  extended: constraints.maxWidth >= 600,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.book),
                      label: Text('My Journal'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                      // reset currentEntry on Home tap
                      if (value == 0) {
                        // clear currentEntry ready for fresh new entry
                        final appState = context.read<MyAppState>();
                        appState.setCurrentEntry(null);
                      }
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
// JournalHomePage widget
class JournalPage extends StatefulWidget {
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  // repopulate JournalHomePage with selected entry onTap 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var appState = context.watch<MyAppState>();

    // if current entry exists, pre-fill the text and image for viewing and editing
    if (appState.currentEntry != null) {
      controller.text = appState.currentEntry!.text;
      _imagePath = appState.currentEntry!.imagePath;
    } else {
      controller.clear();
      _imagePath = null;
    }
  }
    //capture new Journal Entry
  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Write your travel note...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          if (_imagePath != null && _imagePath!.isNotEmpty)
            kIsWeb
            ? Image.network(_imagePath!, width: 150, height: 150)
            : Image.file(File(_imagePath!), width: 150, height: 150),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture the moment'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (appState.currentEntry != null) {
                    // editing existing entry
                    appState.editEntry(
                      appState.currentEntry!,
                      controller.text,
                      _imagePath ?? "",
                    );
                  } else {
                    // saving new entry
                    appState.saveEntry(controller.text, _imagePath ?? "");
                  }
                  // Reset JournalForm
                  controller.clear();
                  setState(() {
                    _imagePath = null;
                  });

                  // Switch to JournalListingPage
                  final homeState = 
                  context.findAncestorStateOfType<_MyHomePageState>();
                  if (homeState != null) {
                    homeState.setState(() {
                      homeState.selectedIndex = 1;
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// JournalEntriesPage
class JournalListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.entries.isEmpty) {
      return const Center(child: Text('No journal entries yet'));
    }

     return ListView(
      children: [
        for (var entry in appState.entries)
          ListTile(
            leading: entry.imagePath.isNotEmpty
                ? Image.file(File(entry.imagePath), width: 50, height: 50)
                : const Icon(Icons.note),
            title: Text(entry.text),
            onTap: () {
              appState.setCurrentEntry(entry);
              // Jump back to Home (index 0) so JournalPage is visible
              final homeState =
                  context.findAncestorStateOfType<_MyHomePageState>();
              if (homeState != null) {
                homeState.setState(() {
                  homeState.selectedIndex = 0;
                });
              }
            },
            // add trailing delete button
            trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Entry?'),
                      content: const Text('You are about to delete a Journal Entry, Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true), 
                          child: const Text('Delete'),
                          ),
                      ],
                    ),
                  );
                  // delete on confirmation
                  if (confirm == true) {
                    appState.deleteEntry(entry);
                  }
                },
            )
          ),
      ],
    );

  }
}