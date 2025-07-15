//find ~/Library -name "FavKdramaActorsActresses.txt" 2>/dev/null
//find ~/Library -name "FavKDrama.txt" 2>/dev/null


import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';


class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  DateTime? _selectedBirthDate;
  Timer? _ageTimer;
  Duration? _ageDuration;

  final Map<String, bool> _expandedSections = {
    //News Tab
    'UpcomingKDramas': false,
    'TopKDramas2024': false,
    'TopKDramas2023': false,
    'TopKDramas2022': false,
    'TopKDramas2021': false,
    'TopKDramas2020': false,
    'TopKDramas2019': false,
    'TopKDramas2018': false,
    'Actors': false,
    'Actresses': false,

    //Library Tab
    'FinishedKDramas': false,
    'WatchlistKDramas': false,
    'CurrentlyWatchingKDramas': false,
    'FavoriteKDramaActors': false,     
    'FavoriteKDramaActresses': false, 

    //Search Tab
    'SearchGenres': false,
    'SearchYears': false,
    'SearchServices': false,

    //Library Tab
    'RankingDiagram': false,
  };

  final List<String> tierNames = [
    "Can't Stop Watching",
    "Awesome",
    "Good",
    "Alright/Okay",
    "Stopped Watching"
  ];
  late Map<String, List<String>> kdramaTierMap; // Holds image paths per tier

  //News Tab
  List<String> topKDramas2024 = [];
  List<String> topKDramas2023 = [];
  List<String> topKDramas2022 = [];
  List<String> topKDramas2021 = [];
  List<String> topKDramas2020 = [];
  List<String> topKDramas2019 = [];
  List<String> topKDramas2018 = [];
  List<String> topActors = [];
  List<String> topActresses = [];

  //Library Tab
  List<String> favActors = [];
  List<String> favActresses = [];
  List<String> upcomingKDramas = [];

  //Library Tab & News Tab
  Map<String, Map<String, List<String>>> kdramaInfoData = {}; //For KDramaInfo.txt
  Map<String, Map<String, dynamic>> actorBioData = {}; //Actrors-Actresses Information

  //Library Tab
  Map<String, Map<String, List<String>>> userKDramaLists = {}; //For FavKDrama.txt
  Map<String, Map<String, List<String>>> userKDramaData = {};
  Map<String, List<String>> userActorActressData = {};

  List<Widget> _pages = [];
  @override
  void dispose() {
    _ageTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadKDramaNews(); //News Tab
    loadUserBio();
    loadFinKDrama(); //Library Tab
    loadFavKDramaActorActresses(); //Library Tab
    loadKDramaInfo(); //Library Tab & News Tab
    loadKDramaActorsActressesBio(); //Library Tab & News Tab
    loadKDramaRanking(widget.username);

    //Social Tab
    loadKDramaRanking(widget.username);
    kdramaTierMap = { //<-
      for (final tier in tierNames) tier: [],
    };
  }

  final List<String> _selectedGenres = [];
  final List<String> _selectedService = [];
  String? _selectedYear;
  String _searchQuery = '';
  String _getKDramaImagePath(String title) {
    return 'build/Images/Show/$title.jpg';
  }

  List<String> getFinishedKDramaImages() {
    final finishedKDramas = userKDramaData[widget.username]?['Fin'] ?? [];
    final alreadyAssigned = kdramaTierMap.values.expand((v) => v).toSet();

    return finishedKDramas
        .map(_getKDramaImagePath)
        .where((path) => !alreadyAssigned.contains(path))
        .toList();
  }


  List<String> getFilteredKDramas() {
    final query = _searchQuery.toLowerCase();
    final List<String> allKDramas = userKDramaData.keys.toList();

    return allKDramas.where((kdrama) {
      final lowerName = kdrama.toLowerCase();
      final genreList = userKDramaData[kdrama]?['-Genre'] ?? [];
      final yearList = userKDramaData[kdrama]?['-Year'] ?? [];
      final serviceList = userKDramaData[kdrama]?['-Streaming Service'] ?? [];

      final genreWords = genreList
          .expand((g) => g.split('/'))
          .map((g) => g.trim().toLowerCase());

      final genreMatch = _selectedGenres.isEmpty || genreWords.any((g) => _selectedGenres.contains(g));
      final yearMatch = _selectedYear == null || yearList.contains(_selectedYear);
      final queryMatch = lowerName.contains(query);

      final serviceWords = serviceList.map((s) => s.toLowerCase());
      final serviceMatch = _selectedService.isEmpty || serviceWords.any((s) => _selectedService.contains(s));

      return queryMatch && genreMatch && yearMatch && serviceMatch;
    }).toList();
  }

  Future<String> _getFinKDramaFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/FavKDrama.txt';
  }

  Future<String> _getBioFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/user_bio_${widget.username}.txt';
}

  Future<void> loadUserBio() async {
    try {
      final path = await _getBioFilePath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _userBio = content.trim().isEmpty ? "Tap 'Edit Profile' to add your bio." : content;
        });
      }
    } catch (e) {
      debugPrint("Error loading bio: $e");
    }
  }


  Future<void> saveKDramaRanking(String username) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/KDramaRanking_$username.txt');
    final buffer = StringBuffer();

    kdramaTierMap.forEach((tier, images) {
      buffer.writeln('$tier: ${images.join(',')}');
    });

    await file.writeAsString(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ranking saved!')),
    );
  }



  Future<String> _getFavActorsFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final userDataDir = Directory('${dir.path}/User Data');

    // Ensure the 'User Data' directory exists
    if (!await userDataDir.exists()) {
      await userDataDir.create(recursive: true);
    }
    return '${userDataDir.path}/FavKdramaActorsActresses.txt';
  }

  Future<void> loadFavKDramaActorActresses() async {
    final path = await _getFavActorsFilePath();
    final file = File(path);

    if (!await file.exists()) {
      await file.create(recursive: true);
      return;
    }

    final lines = await file.readAsLines();
    String? currentUser;

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith("User:")) {
        currentUser = line.split(':')[1].trim();
        userActorActressData[currentUser] = [];
      } else if (line.startsWith("FavActors:") && currentUser != null) {
        final actors = line.replaceFirst("FavActors:", "").split(',').map((e) => e.trim()).toList();
        userActorActressData[currentUser]?.addAll(actors);
      } else if (line.startsWith("FavActresses:") && currentUser != null) {
        final actresses = line.replaceFirst("FavActresses:", "").split(',').map((e) => e.trim()).toList();
        userActorActressData[currentUser]?.addAll(actresses);
      }
    }
    setState(() {});
  }

  Future<void> _updateUserKDramaCategory(String username, String kdrama, String category) async {
    final path = await _getFinKDramaFilePath();
    final file = File(path);

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    final lines = await file.readAsLines();
    List<String> updatedLines = [];

    String? currentUser;
    List<String> fin = [], cur = [], wat = [];
    bool userFound = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('User:')) {
        // Save previous user data
        if (currentUser != null) {
          updatedLines.add('User: $currentUser');
          updatedLines.add('Fin: ${fin.join(', ')}');
          updatedLines.add('Cur: ${cur.join(', ')}');
          updatedLines.add('Wat: ${wat.join(', ')}');
        }

        // New user starts
        currentUser = line.split(':')[1].trim();
        fin = [];
        cur = [];
        wat = [];

        if (currentUser == username) userFound = true;

      } else if (line.startsWith('Fin:')) {
        fin = line.replaceFirst('Fin:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (line.startsWith('Cur:')) {
        cur = line.replaceFirst('Cur:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (line.startsWith('Wat:')) {
        wat = line.replaceFirst('Wat:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    // After loop: update or add final user
    if (currentUser != null && currentUser == username) {
      if (category == 'Fin' && !fin.contains(kdrama)) fin.add(kdrama);
      if (category == 'Cur' && !cur.contains(kdrama)) cur.add(kdrama);
      if (category == 'Wat' && !wat.contains(kdrama)) wat.add(kdrama);

      updatedLines.add('User: $currentUser');
      updatedLines.add('Fin: ${fin.join(', ')}');
      updatedLines.add('Cur: ${cur.join(', ')}');
      updatedLines.add('Wat: ${wat.join(', ')}');
    }

    if (!userFound) {
      updatedLines.add('User: $username');
      updatedLines.add(category == 'Fin' ? 'Fin: $kdrama' : 'Fin:');
      updatedLines.add(category == 'Cur' ? 'Cur: $kdrama' : 'Cur:');
      updatedLines.add(category == 'Wat' ? 'Wat: $kdrama' : 'Wat:');
    }

    print('Writing to: $path');
    print('Updated file content:\n${updatedLines.join('\n')}');
    await file.writeAsString(updatedLines.join('\n') + '\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Added to your $category list."), backgroundColor: Colors.green),
    );
    await loadFinKDrama(); // Refresh UI
  }

  Future<void> updateFavoriteActor(String username, String name, bool isActress) async {
    final path = await _getFavActorsFilePath();
    final file = File(path);

    final lines = await file.readAsLines();
    List<String> updatedLines = [];
    String? currentUser;
    List<String> favActors = [], favActresses = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('User:')) {
        if (currentUser != null) {
          updatedLines.add('User: $currentUser');
          updatedLines.add('FavActors: ${favActors.join(', ')}');
          updatedLines.add('FavActresses: ${favActresses.join(', ')}');
        }
        currentUser = trimmed.split(':')[1].trim();
        favActors = [];
        favActresses = [];
      } else if (trimmed.startsWith('FavActors:')) {
        favActors = trimmed.replaceFirst('FavActors:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } else if (trimmed.startsWith('FavActresses:')) {
        favActresses = trimmed.replaceFirst('FavActresses:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    if (currentUser == username) {
      final list = isActress ? favActresses : favActors;
      if (list.contains(name)) {
        list.remove(name);
      } else {
        list.add(name);
      }
      updatedLines.add('User: $currentUser');
      updatedLines.add('FavActors: ${favActors.join(', ')}');
      updatedLines.add('FavActresses: ${favActresses.join(', ')}');
    }

    await file.writeAsString(updatedLines.join('\n') + '\n');
    await loadFavKDramaActorActresses();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${name} has been ${isActress ? 'updated in your Favorite Actresses' : 'updated in your Favorite Actors'} list."),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> loadKDramaRanking(String username) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/KDramaRanking_$username.txt');

  if (await file.exists()) {
    final lines = await file.readAsLines();
    final Map<String, List<String>> loadedMap = {};

    for (final line in lines) {
      final parts = line.split(':');
      if (parts.length >= 2) {
        final tier = parts[0].trim();
        final images = parts.sublist(1).join(':').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        loadedMap[tier] = images;
      }
    }

    setState(() {
      kdramaTierMap = {
        for (final tier in tierNames)
          tier: loadedMap[tier] ?? [],
      };
    });
  }
}


  Future<void> loadKDramaInfo() async {
  final fileContent = await rootBundle.loadString('lib/KDramaInfo.txt');
  final lines = const LineSplitter().convert(fileContent);

  String? currentKDrama;

  for (var line in lines) {
    line = line.trim();
    if (line.startsWith("KDrama:")) {
      currentKDrama = line.replaceFirst("KDrama:", "").replaceAll(':', '').trim();
      userKDramaData[currentKDrama] = {
        '-Year': [],
        '-Genre': [],
        '-Cast': [],
        '-Info': [],
        '-Streaming Service': [],
        '-Awards': [],
        '-YouTube': [],
        '-Spotify': [],
      };
    } else if (currentKDrama != null && line.contains(":")) {
      final separatorIndex = line.indexOf(':');
      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();

      if (userKDramaData[currentKDrama]!.containsKey(key)) {
        userKDramaData[currentKDrama]![key] = [value];
      }
    }
  }
  setState(() {});
}

Future<void> _removeUserKDramaCategory(String username, String kdrama, String category) async {
  final path = await _getFinKDramaFilePath();
  final file = File(path);

  if (!await file.exists()) return;

  final lines = await file.readAsLines();
  List<String> updatedLines = [];

  String? currentUser;
  List<String> fin = [], cur = [], wat = [];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    if (line.startsWith('User:')) {
      if (currentUser != null) {
        updatedLines.add('User: $currentUser');
        updatedLines.add('Fin: ${fin.join(', ')}');
        updatedLines.add('Cur: ${cur.join(', ')}');
        updatedLines.add('Wat: ${wat.join(', ')}');
      }
      currentUser = line.split(':')[1].trim();
      fin = []; cur = []; wat = [];
    } else if (line.startsWith('Fin:')) {
      fin = line.replaceFirst('Fin:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (line.startsWith('Cur:')) {
      cur = line.replaceFirst('Cur:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (line.startsWith('Wat:')) {
      wat = line.replaceFirst('Wat:', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }

  if (currentUser == username) {
    if (category == 'Fin') fin.remove(kdrama);
    if (category == 'Cur') cur.remove(kdrama);
    if (category == 'Wat') wat.remove(kdrama);
  }

  if (currentUser != null) {
    updatedLines.add('User: $currentUser');
    updatedLines.add('Fin: ${fin.join(', ')}');
    updatedLines.add('Cur: ${cur.join(', ')}');
    updatedLines.add('Wat: ${wat.join(', ')}');
  }

  await file.writeAsString(updatedLines.join('\n') + '\n');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Removed from your $category list."), backgroundColor: Colors.red));
  await loadFinKDrama();
}


List<String> parseAwardEntry(String award) {
  final yearRegex = RegExp(r'\b(19|20)\d{2}\b');
  final quoteRegex = RegExp(r'"(.*?)"');
  final parenRegex = RegExp(r'\((.*?)\)');

  String name = award;
  String year = '';
  String drama = '';
  String association = '';

  // Find year
  final yearMatch = yearRegex.firstMatch(award);
  if (yearMatch != null) {
    year = yearMatch.group(0)!;
  }

  // Find drama
  final dramaMatch = quoteRegex.firstMatch(award);
  if (dramaMatch != null) {
    drama = dramaMatch.group(1)!;
  }

  // Find association in parentheses
  final parenMatch = parenRegex.firstMatch(award);
  if (parenMatch != null) {
    final inside = parenMatch.group(1)!;
    if (year.isNotEmpty && inside.contains(year)) {
      association = inside.replaceFirst(year, '').trim();
    } else {
      association = inside.trim();
    }
  }

  // Clean the name
  if (parenMatch != null) {
    name = name.replaceFirst('(${parenMatch.group(1)})', '').trim();
  }
  if (drama.isNotEmpty) {
    name = name.replaceFirst('in "$drama"', '').trim();
  }

  return [name, year, drama, association];
}


Future<void> loadKDramaActorsActressesBio() async {
  final fileContent = await rootBundle.loadString('lib/KDramaActorsActressesBio.txt');
  final lines = const LineSplitter().convert(fileContent);

  String? currentActor;
  String? currentSection;

  for (var rawLine in lines) {
    final line = rawLine.trim();

    if (line.startsWith("Actor:") || line.startsWith("Actress:")) {
      currentActor = line.split(':')[1].trim();
      actorBioData[currentActor] = {
        'Born': '',
        'Individual Awards': <String>[],
        'KDrama Awards': <String>[],
        'KDrama Series': <String>[],
        'Instagram': ''
      };
      currentSection = null;
    } else if (currentActor != null) {
      if (line.startsWith("-Born:")) {
        actorBioData[currentActor]!['Born'] = line.replaceFirst("-Born:", "").trim();
      } else if (line.startsWith("-Individual Awards:")) {
        currentSection = 'Individual Awards';
      } else if (line.startsWith("-KDrama Awards:")) {
        currentSection = 'KDrama Awards';
      } else if (line.startsWith("-KDrama Series (Main Roles):")) {
        actorBioData[currentActor]!['KDrama Series'] =
            line.replaceFirst("-KDrama Series (Main Roles):", "").split(',').map((e) => e.trim()).toList();
        currentSection = null;
      } else if (line.startsWith("-Instagram:")) {
        actorBioData[currentActor]!['Instagram'] = line.replaceFirst("-Instagram:", "").trim();
        currentSection = null;
      } else if (line.startsWith("-")) {
        // Award item
        final cleaned = line.replaceFirst("-", "").trim();
        if (currentSection != null && actorBioData[currentActor]![currentSection] != null) {
          (actorBioData[currentActor]![currentSection] as List<String>).add(cleaned);
        }
      }
    }
  }
  setState(() {});
}

  Future<void> loadFinKDrama() async {
    //final String fileContent = await rootBundle.loadString('lib/User Data/FavKDrama.txt');
    final path = await _getFinKDramaFilePath();
    final file = File(path);


      if (!await file.exists()) {
        await file.create(recursive: true);
        return;
      }

    final lines = await file.readAsLines();

    String? currentUser;
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith("User:")) {
        currentUser = line.split(':')[1].trim();
        userKDramaData[currentUser] = {
          'Fin': [],
          'Cur': [],
          'Wat': []
        };
      } else if (line.startsWith("Fin:") && currentUser != null) {
        userKDramaData[currentUser]!['Fin'] = line.replaceFirst("Fin:", '').split(',').map((e) => e.trim()).toList();
      } else if (line.startsWith("Cur:") && currentUser != null) {
        userKDramaData[currentUser]!['Cur'] = line.replaceFirst("Cur:", '').split(',').map((e) => e.trim()).toList();
      } else if (line.startsWith("Wat:") && currentUser != null) {
        userKDramaData[currentUser]!['Wat'] = line.replaceFirst("Wat:", '').split(',').map((e) => e.trim()).toList();
      }
    }
    setState(() {});
  }

  Future<void> loadKDramaNews() async {
    final String fileContent = await rootBundle.loadString('lib/KDramaNews.txt');
    final lines = LineSplitter().convert(fileContent);

    String? currentSection;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('Top KDramas 2024')) {
        currentSection = 'TopKDramas2024';
        continue;
      } else if (line.startsWith('Top KDramas 2023')) {
        currentSection = 'TopKDramas2023';
        continue;
      } else if (line.startsWith('Top KDramas 2022')) {
        currentSection = 'TopKDramas2022';
        continue;
      } else if (line.startsWith('Top KDramas 2021')) {
        currentSection = 'TopKDramas2021';
        continue;
      } else if (line.startsWith('Top KDramas 2020')) {
        currentSection = 'TopKDramas2020';
        continue;
      } else if (line.startsWith('Top KDramas 2019')) {
        currentSection = 'TopKDramas2019';
        continue;
      } else if (line.startsWith('Top KDramas 2018')) {
        currentSection = 'TopKDramas2018';
        continue;
      }else if (line.startsWith('Top KDrama Actors')) {
        currentSection = 'Actors';
        continue;
      } else if (line.startsWith('Top KDrama Actresses')) {
        currentSection = 'Actresses';
        continue;
      } else if (line.startsWith('Upcoming KDramas')) {
        currentSection = 'UpcomingKDramas';
        continue;
      }

      final cleanedLine = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
      switch (currentSection) {
        case 'TopKDramas2024':
          topKDramas2024.add(cleanedLine);
          break;
        case 'TopKDramas2023':
          topKDramas2023.add(cleanedLine);
          break;
        case 'TopKDramas2022':
          topKDramas2022.add(cleanedLine);
          break;
        case 'TopKDramas2021':
          topKDramas2021.add(cleanedLine);
          break;
        case 'TopKDramas2020':
          topKDramas2020.add(cleanedLine);
          break;
        case 'TopKDramas2019':
          topKDramas2019.add(cleanedLine);
          break;
        case 'TopKDramas2018':
          topKDramas2018.add(cleanedLine);
          break;
        case 'Actors':
          topActors.add(cleanedLine);
          break;
        case 'Actresses':
          topActresses.add(cleanedLine);
          break;
        case 'UpcomingKDramas':
          upcomingKDramas.add(cleanedLine);
          break;
      }
    }

    setState(() {});
  }

  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  void _toggleSection(String key) {
    setState(() {
      _expandedSections[key] = !_expandedSections[key]!;
    });
  }

void showActorActressBio(String name) {
  final isActress = topActresses.contains(name);
  final bio = actorBioData[name];

  if (bio == null) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: const Text("Biography information not available."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
    return;
  }

  if (bio['Born'] != '') {
    _startLiveAgeClock(bio['Born']);
  }

  final kdramas = (bio['KDrama Series'] as List<String>).join(', ');
  final instagram = bio['Instagram'];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          if (bio['Born'] != '') {
            _ageTimer?.cancel(); // Stop previous timer
            final parsedDate = DateTime.tryParse(_normalizeBirthDate(bio['Born']));
            if (parsedDate != null) {
              _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                final now = DateTime.now();
                setModalState(() {
                  _ageDuration = now.difference(parsedDate);
                });
              });
            }
          }

          return AlertDialog(
            title: Text(name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bio['Born'] != '') ...[
                    Text("Born: ${bio['Born']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    if (_ageDuration != null)
                      Text("Age: ${_formatAge(_ageDuration!)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                  if ((bio['Individual Awards'] as List<String>).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text("Individual Awards:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Table(
                      border: TableBorder.all(width: 0.5, color: Colors.grey),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('Name of the Award', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Association', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...List<TableRow>.generate(
                          (bio['Individual Awards'] as List<String>).length,
                          (index) {
                            final fullRow = parseAwardEntry((bio['Individual Awards'] as List<String>)[index]);
                            final row = fullRow.sublist(0, 1) + [fullRow[1], fullRow[3]];
                            return TableRow(
                              children: row.map((cell) => Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(cell, style: const TextStyle(fontSize: 11)),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  if ((bio['KDrama Awards'] as List<String>).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text("KDrama Awards:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Table(
                      border: TableBorder.all(width: 0.5, color: Colors.grey),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
                          children: [
                            Padding(padding: EdgeInsets.all(6), child: Text('Name of the Award', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Drama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.all(6), child: Text('Association', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ...List<TableRow>.generate(
                          (bio['KDrama Awards'] as List<String>).length,
                          (index) {
                            final awardRow = parseAwardEntry((bio['KDrama Awards'] as List<String>)[index]);
                            return TableRow(
                              children: awardRow.map((cell) => Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(cell, style: const TextStyle(fontSize: 11)),
                              )).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                  if (kdramas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text("KDrama Series:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(kdramas),
                  ],
                  if (instagram.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(instagram), mode: LaunchMode.externalApplication),
                      icon: Image.asset('build/Images/instagramLogo.png', width: 20, height: 20),
                      label: const Text(
                        "View on Instagram",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFE1306C),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
            TextButton(
              onPressed: () async {
                await updateFavoriteActor(widget.username, name, isActress);
                await loadFavKDramaActorActresses(); // make sure it updates the local state
                setModalState(() {}); // force rebuild with new isFav status
                //Navigator.pop(context); // close the dialog after adding/removing
              },
              child: Text(
                (userActorActressData[widget.username]?.contains(name) ?? false)
                  ? "Remove from Favorites"
                  : "Add to Favorites",
                //isFav ? "Remove from Favorites" : "Add to Favorites"
                ),
            ),
            TextButton(
              onPressed: () {
                _ageTimer?.cancel(); // stop timer when dialog closes
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
          );
        },
      );
    },
  );
}

  Widget _buildStatBox(String label, int value) {
  return Column(
    children: [
      Text(
        "$value",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ],
  );
}

Widget buildTierRow(String tierName) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tierName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          height: 70, 
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DragTarget<String>(
            onAccept: (imgPath) {
              setState(() {
                // Remove image from other tiers
                for (final list in kdramaTierMap.values) {
                  list.remove(imgPath);
                }
                kdramaTierMap[tierName]?.add(imgPath);
              });
            },
            builder: (context, candidateData, rejectedData) {
              final images = kdramaTierMap[tierName]!;
              return ListView(
                scrollDirection: Axis.horizontal,
                children: images.map((imgPath) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.asset(imgPath, height: 60),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              kdramaTierMap[tierName]?.remove(imgPath);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget buildRankingExpanded() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 6),
      ...tierNames.map((tier) => buildTierRow(tier)).toList(),
    ],
  );
}

Widget buildRankingBoard() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "K-Dramas Ranked:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          buildToggleButton('RankingDiagram'),
        ],
      ),
      if (_expandedSections['RankingDiagram'] ?? false)
        buildRankingExpanded(),
    ],
  );
}

String _userBio = "Tap 'Edit Profile' to add your bio.";
String _getInitials(String username) {
  final matches = RegExp(r'[A-Z]').allMatches(username);
  final initials = matches.map((match) => match.group(0)!).join();
  return initials.isNotEmpty ? initials : username.substring(0, 1).toUpperCase();
}
void _showEditProfileDialog() {
  final TextEditingController _bioController = TextEditingController(text: _userBio);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Profile"),
        content: TextField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Write something about yourself...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _userBio = _bioController.text.trim().isEmpty
                    ? "Tap 'Edit Profile' to add your bio."
                    : _bioController.text.trim();
              });

              final path = await _getBioFilePath();
              final file = File(path);
              await file.writeAsString(_userBio);

              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}



  Widget buildToggleButton(String key) {
    final isExpanded = _expandedSections[key]!;
    return TextButton(
      onPressed: () => _toggleSection(key),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpanded ? "Show less" : "Show more",
            style: const TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          Icon(
            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  String extractYouTubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '';

  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.first;
  } else if (uri.host.contains('youtube.com') && uri.queryParameters.containsKey('v')) {
    return uri.queryParameters['v'] ?? '';
  }

  return '';
}

GestureDetector buildFileColumnFin(String image, double availableScreenWidth, int index) {
  return GestureDetector(
    onTap: () {
      final dramaDetails = userKDramaData[image];
      String infoText = "";
      String? youtubeUrl;
      String? spotifyUrl;

      if (dramaDetails != null) {
        infoText = dramaDetails.entries
          .where((entry) => entry.key != '-YouTube' && entry.key != '-Spotify') // <-- this fixes it
          .map((entry) {
            final key = entry.key.replaceAll('-', '').trim();
            final value = entry.value.join(', ');
            return "$key: $value";
          })
          .join('\n');
        youtubeUrl = dramaDetails['-YouTube']?.isNotEmpty == true ? dramaDetails['-YouTube']![0] : null;
        spotifyUrl = dramaDetails['-Spotify']?.isNotEmpty == true ? dramaDetails['-Spotify']![0] : null;
      }

      if (youtubeUrl != null) {
        final videoId = extractYouTubeId(youtubeUrl);
        final embedUrl = 'https://www.youtube.com/embed/$videoId';
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(image),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      infoText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if ((userKDramaData[widget.username]?['Fin'] ?? []).contains(image))
                      TextButton(
                        onPressed: () => _removeUserKDramaCategory(widget.username, image, 'Fin'),
                        child: const Text("Remove from Finished KDramas"),
                      )
                    else
                      TextButton(
                        onPressed: () => _updateUserKDramaCategory(widget.username, image, 'Fin'),
                        child: const Text("Add to Finished KDramas"),
                      ),
                    if ((userKDramaData[widget.username]?['Cur'] ?? []).contains(image))
                      TextButton(
                        onPressed: () => _removeUserKDramaCategory(widget.username, image, 'Cur'),
                        child: const Text("Remove from Currently Watching"),
                      )
                    else
                      TextButton(
                        onPressed: () => _updateUserKDramaCategory(widget.username, image, 'Cur'),
                        child: const Text("Add to Currently Watching"),
                      ),
                    if ((userKDramaData[widget.username]?['Wat'] ?? []).contains(image))
                      TextButton(
                        onPressed: () => _removeUserKDramaCategory(widget.username, image, 'Wat'),
                        child: const Text("Remove from Watchlist"),
                      )
                    else
                      TextButton(
                        onPressed: () => _updateUserKDramaCategory(widget.username, image, 'Wat'),
                        child: const Text("Add to Watchlist"),
                      ),
                    if (spotifyUrl != null)
                      TextButton.icon(
                        onPressed: () async {
                          final url = spotifyUrl!;
                          try {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Could not launch Spotify URL: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to open Spotify link.')),
                            );
                          }
                        },
                        icon: Image.asset('build/Images/spotifyLogo.png', width: 20, height: 20),
                        label: const Text(
                          "Listen on Spotify",
                          style: TextStyle(
                            color: Colors.black, // black text
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF1DB954), // Spotify green
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: WebViewWidget(
                        controller: WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..loadRequest(Uri.parse(embedUrl)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(formatKdramaTitle(image)),
            content: Text(infoText.isNotEmpty ? infoText : "More information about $image will appear here."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          ),
        );
      }
    },
    child: SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: availableScreenWidth * .27,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            height: 200,
            child: Image.asset('build/Images/Show/$image.jpg', fit: BoxFit.cover),
          ),
          RichText(
            text: TextSpan(
              text: "$index. ${formatKdramaTitle(image)}",
              style: const TextStyle(color: Colors.black, fontSize: 8),
            ),
          ),
        ],
      ),
    ),
  );
}

  Column buildFileColumnRec(String image, double availableScreenWidth) {
    return Column(
      children: [
        Container(
          width: availableScreenWidth * .27, // Now uses the passed screen width
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          height: 200,
          child: Image.asset('build/Images/Show/$image.jpg', fit: BoxFit.cover),
        ),
        RichText(
          text: TextSpan(
            text: formatKdramaTitle(image),
            style: TextStyle(
              color: Colors.black,
              fontSize: 8
            ),
          ),
        ),
      ],
    );
  }

  GestureDetector buildFileColumnTopActors(String image, double availableScreenWidth, int actorRankIndex) {
  return GestureDetector(
    onTap: () => showActorActressBio(image),
    child: Column(
      children: [
        Container(
          width: availableScreenWidth * .27,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          height: 200,
          child: Image.asset('build/Images/Actors/$image.jpg', fit: BoxFit.cover),
        ),
        RichText(
          text: TextSpan(
            text: "$actorRankIndex. ${formatKdramaTitle(image)}",
            style: const TextStyle(color: Colors.black, fontSize: 8),
          ),
        ),
      ],
    ),
  );
}

  GestureDetector buildFileColumnTopActresses(String image, double availableScreenWidth, int actorRankIndex) {
  return GestureDetector(
    onTap: () => showActorActressBio(image),
    child: Column(
      children: [
        Container(
          width: availableScreenWidth * .27,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          height: 200,
          child: Image.asset('build/Images/Actresses/$image.jpg', fit: BoxFit.cover),
        ),
        RichText(
          text: TextSpan(
            text: "$actorRankIndex. ${formatKdramaTitle(image)}",
            style: const TextStyle(color: Colors.black, fontSize: 8),
          ),
        ),
      ],
    ),
  );
}

  String formatKdramaTitle(String title) {
    if (title.length <= 20) return title;

    return title
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map((word) => word[0].toUpperCase())
      .join('.');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void resetKDramaRanking() {
  setState(() {
    for (final tier in tierNames) {
      kdramaTierMap[tier] = [];
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Ranking has been reset."),
      backgroundColor: Colors.redAccent,
    ),
  );
}

  void _startLiveAgeClock(String? bornString) {
    _ageTimer?.cancel(); // cancel previous timer if running

    if (bornString == null || bornString.isEmpty) return;

    try {
      final parsedDate = DateTime.parse(_normalizeBirthDate(bornString));
      _selectedBirthDate = parsedDate;

      _ageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        setState(() {
          _ageDuration = now.difference(parsedDate);
        });
      });
    } catch (e) {
      debugPrint("Failed to parse birth date: $e");
    }
  }

  String _normalizeBirthDate(String raw) {
    try {
      return DateFormat("MMM d, yyyy").parse(raw).toIso8601String();
    } catch (_) {
      // fallback to just year if needed
      final yearMatch = RegExp(r'\d{4}').firstMatch(raw);
      if (yearMatch != null) {
        return "$yearMatch-01-01T00:00:00Z";
      }
      throw FormatException("Invalid birth date format");
    }
  }

  String _formatAge(Duration duration) {
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = (duration.inDays % 365) % 30;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return "$years years, $months months, $days days, ""$hours hrs, $minutes mins, $seconds secs";
  }

  Widget buildFinishedKDramaImagesRow() { //<-
    final finishedKDramas = userKDramaData[widget.username]?['Fin'] ?? [];
    final List<String> unassignedImages = getFinishedKDramaImages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        /*const Text(
          "Drag Finished K-Dramas:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),*/
        //const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: unassignedImages.map((img) {
              return Draggable<String>(
                data: img,
                feedback: Material(child: Image.asset(img, height: 60)),
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset(img, height: 60)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(img, height: 60),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final double availableScreenWidth = MediaQuery.of(context).size.width;
    final List<String> finishedKDramas = userKDramaData[widget.username]?['Fin'] ?? [];
    final List<String> currentlyWatchingKDramas = userKDramaData[widget.username]?['Cur'] ?? [];
    final List<String> watchlistKDramas = userKDramaData[widget.username]?['Wat'] ?? [];

    final favActors = (userActorActressData[widget.username] ?? [])
      .where((actor) => topActors.contains(actor))
      .toList();

    final favActresses = (userActorActressData[widget.username] ?? [])
      .where((actress) => topActresses.contains(actress))
      .toList();

    _pages = <Widget>[
      SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Upcoming K-Dramas in 2025:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (upcomingKDramas.length > 3) buildToggleButton('UpcomingKDramas'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['UpcomingKDramas'] ?? false)
                ? upcomingKDramas.length
                : (upcomingKDramas.length > 3 ? 3 : upcomingKDramas.length),
                (index) => buildFileColumnFin(upcomingKDramas[index], availableScreenWidth, index + 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2024:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2024.length > 3) buildToggleButton('TopKDramas2024'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2024'] ?? false)
                ? topKDramas2024.length
                : (topKDramas2024.length > 3 ? 3 : topKDramas2024.length),
                (index) => buildFileColumnFin(topKDramas2024[index], availableScreenWidth, index + 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2023:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2023.length > 3) buildToggleButton('TopKDramas2023'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2023'] ?? false)
                ? topKDramas2023.length
                : (topKDramas2023.length > 3 ? 3 : topKDramas2023.length),
                (index) => buildFileColumnFin(topKDramas2023[index], availableScreenWidth, index + 1),
            ),
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2022:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2022.length > 3) buildToggleButton('TopKDramas2022'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2022'] ?? false)
                ? topKDramas2022.length
                : (topKDramas2022.length > 3 ? 3 : topKDramas2022.length),
                (index) => buildFileColumnFin(topKDramas2022[index], availableScreenWidth, index + 1),
            ),
          ), 
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2021:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2021.length > 3) buildToggleButton('TopKDramas2021'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2021'] ?? false)
                ? topKDramas2021.length
                : (topKDramas2021.length > 3 ? 3 : topKDramas2021.length),
                (index) => buildFileColumnFin(topKDramas2021[index], availableScreenWidth, index + 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2020:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2020.length > 3) buildToggleButton('TopKDramas2020'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2020'] ?? false)
                ? topKDramas2020.length
                : (topKDramas2020.length > 3 ? 3 : topKDramas2020.length),
                (index) => buildFileColumnFin(topKDramas2020[index], availableScreenWidth, index + 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2019:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2019.length > 3) buildToggleButton('TopKDramas2019'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2019'] ?? false)
                ? topKDramas2019.length
                : (topKDramas2019.length > 3 ? 3 : topKDramas2019.length),
                (index) => buildFileColumnFin(topKDramas2019[index], availableScreenWidth, index + 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Dramas in 2018:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topKDramas2018.length > 3) buildToggleButton('TopKDramas2018'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['TopKDramas2018'] ?? false)
                ? topKDramas2018.length
                : (topKDramas2018.length > 3 ? 3 : topKDramas2018.length),
                (index) => buildFileColumnFin(topKDramas2018[index], availableScreenWidth, index + 1),
            ),
          ), 
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Drama Actors:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topActors.length > 3) buildToggleButton('Actors'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['Actors'] ?? false)
                ? topActors.length
                : (topActors.length > 3 ? 3 : topActors.length),
                (index) => buildFileColumnTopActors(topActors[index], availableScreenWidth, index + 1),
            ),
          ),
          

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Top K-Drama Actresses:",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (topActresses.length > 3) buildToggleButton('Actresses'),
            ],
          ),
          Wrap(
            spacing: availableScreenWidth * 0.03,
            runSpacing: 10,
            children: List.generate(
              (_expandedSections['Actresses'] ?? false)
                ? topActresses.length
                : (topActresses.length > 3 ? 3 : topActresses.length),
                (index) => buildFileColumnTopActresses(topActresses[index], availableScreenWidth, index + 1),
            ),
          ),
          ],
        ),
      ),
      Center(
        child: Column(
          children: [
            if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: availableScreenWidth * 0.02,
                    children: (_expandedSections['SearchGenres']!
                        ? ["Romance", "Drama", "Action", "Comedy", "Mystery", "Fantasy", "Thriller", "Revenge", "Horror", "Youth", "Physchological", "Crime", "Business","Sci-Fi", "Historical"]
                        : ["Romance", "Drama", "Action", "Comedy", "Mystery"]
                    ).map((genre) {
                      final isSelected = _selectedGenres.contains(genre.toLowerCase());
                      return FilterChip(
                        label: Text(
                          genre,
                          style: const TextStyle(fontSize: 8),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre.toLowerCase());
                            } else {
                              _selectedGenres.remove(genre.toLowerCase());
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (["Romance", "Drama", "Action", "Comedy", "Mystery", "Fantasy", "Thriller", "Revenge", "Horror", "Youth", "Physchological", "Crime", "Business", "Sci-Fi", "Historical"].length > 5) buildToggleButton('SearchGenres'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: availableScreenWidth * 0.02,
                    children: (_expandedSections['SearchYears']!
                      ? ["2025", "2024", "2023", "2022", "2021", "2020", "2019", "2018"]
                      : ["2025", "2024", "2023", "2022", "2021"]
                    ).map((year) {
                      return ChoiceChip(
                        label: Text(year, style: const TextStyle(fontSize: 8)),
                        selected: _selectedYear == year,
                        onSelected: (selected) {
                          setState(() {
                            _selectedYear = selected ? year : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  buildToggleButton('SearchYears'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: availableScreenWidth * 0.02,
                    children: (_expandedSections['SearchServices']!
                      ? ["Netflix", "Viki", "Prime Video", "MBC", "Hulu", "Disney+", "OnDemandKorea", "Roku", "Apple TV"]
                      : ["Netflix", "Viki", "Prime Video", "MBC", "Hulu"]
                    ).map((service) {
                      final isSelected = _selectedService.contains(service.toLowerCase());
                      return FilterChip(
                        label: Text(service, style: const TextStyle(fontSize: 8)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedService.add(service.toLowerCase());
                            } else {
                              _selectedService.remove(service.toLowerCase());
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  buildToggleButton('SearchServices'),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.7,
                  children: getFilteredKDramas().map((drama) {
                    return buildFileColumnFin(drama, MediaQuery.of(context).size.width, 0);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      Center(
        child: ListView(
          padding: const EdgeInsets.all(25),
          children: [
            const Text(
              "Your Finished K-Dramas:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: availableScreenWidth * 0.03,
              runSpacing: 10,
              children: List.generate(
                _expandedSections['FinishedKDramas']! ? finishedKDramas.length : (finishedKDramas.length > 3 ? 3 : finishedKDramas.length),
                (index) => buildFileColumnFin(finishedKDramas[index], availableScreenWidth, index + 1),
              ),
            ),
            if (finishedKDramas.length > 3) buildToggleButton('FinishedKDramas'),
            const Text(
              "Currently Watching K-Dramas:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              spacing: availableScreenWidth * 0.03,
              runSpacing: 10,
              children: List.generate(
                _expandedSections['CurrentlyWatchingKDramas']! ? currentlyWatchingKDramas.length : (currentlyWatchingKDramas.length > 3 ? 3 : currentlyWatchingKDramas.length),
                (index) => buildFileColumnFin(currentlyWatchingKDramas[index], availableScreenWidth, index + 1),
              ),
            ),
            if (currentlyWatchingKDramas.length > 3) buildToggleButton('CurrentlyWatchingKDramas'),
            const SizedBox(height: 10),

            const Text(
              "K-Drama Watchlist:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Wrap(
              spacing: availableScreenWidth * 0.03,
              runSpacing: 10,
              children: List.generate(
                _expandedSections['WatchlistKDramas']! ? watchlistKDramas.length : (watchlistKDramas.length > 3 ? 3 : watchlistKDramas.length),
                (index) => buildFileColumnFin(watchlistKDramas[index], availableScreenWidth, index + 1),
              ),
            ),
            if (watchlistKDramas.length > 3) buildToggleButton('WatchlistKDramas'),

              const SizedBox(height: 10),
              const Text(
                "Your Favorite K-Drama Actors:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: availableScreenWidth * 0.03,
                runSpacing: 10,
                children: [
                  for (final actor in userActorActressData[widget.username] ?? [])
                    if (favActors.contains(actor))
                      buildFileColumnTopActors(actor, availableScreenWidth, favActors.indexOf(actor) + 1),
                ],
              ),
              if (favActors.length > 3) buildToggleButton('FavoriteKDramaActors'),
            
              const SizedBox(height: 10),
              const Text(
                "Your Favorite K-Drama Actresses:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: availableScreenWidth * 0.03,
                runSpacing: 10,
                children: List.generate(
                  _expandedSections['FavoriteKDramaActresses']!
                    ? favActresses.length
                    : (favActresses.length > 3 ? 3 : favActresses.length),
                  (index) => buildFileColumnTopActresses(favActresses[index], availableScreenWidth, index + 1),
                ),
              ),
              if (favActresses.length > 3) buildToggleButton('FavoriteKDramaActresses'),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Text(
                      _getInitials(widget.username),
                      style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _showEditProfileDialog();
                          },
                          child: const Text("Edit Profile"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatBox("KDrama's Watched", finishedKDramas.length),
                      const SizedBox(height: 6),
                      _buildStatBox("Followers", 120), // You can replace with actual data
                      const SizedBox(height: 6),
                      _buildStatBox("Following", 78),  // Replace with actual data
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "Bio",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _userBio,
                style: const TextStyle(color: Colors.grey),
              ),
              //buildFinishedKDramaImagesRow(),
              const SizedBox(height: 10),
              buildRankingBoard(),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => saveKDramaRanking(widget.username),
                    child: const Text("Save Rankings"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: resetKDramaRanking,
                    child: const Text("Reset"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
              buildFinishedKDramaImagesRow(),  // This is your draggable image row //<-
            ],
          ),
        ),
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: (_selectedIndex == 1 && _isSearching)
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search by name, genre, or year...',
                border: InputBorder.none,
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query.toLowerCase();
                });
              },
            )
          : Text(_getAppBarTitle(_selectedIndex)),
          //_getAppBarTitle(_selectedIndex),
      actions: [
        if (_selectedIndex == 1)
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ],
        backgroundColor: Colors.green,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.new_label), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.social_distance), label: 'Social'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  /*Widget _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return Row(
        children: [
          Image.asset('build/Images/KDram Central.png', height: 30),
          const SizedBox(width: 10),
          const Text("News"),
        ],
      );
      case 1:
        return const Text("Search");
      case 2:
        return const Text("Library");
      case 3:
        return const Text("Social");
      default:
        return Image.asset('build/Images/KDram Central.png', height: 40, fit: BoxFit.contain);
    }*/
  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "News";
      case 1:
        return "Search";
      case 2:
        return "Library";
      case 3:
        return "Social";
      default:
        return "K-Dram";
    }
  }
}

