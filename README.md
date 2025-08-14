# Frontend

This folder contains two UIs connecting to the Spring Boot backend (port 8081):

- web/ — a static HTML page.
- flutter_solar_terrain_analytics/ — a Flutter app for mobile/desktop/web.

## Web UI

Open `frontend/web/index.html` in your browser (or serve with a simple HTTP server). It defaults to `http://localhost:8081` and exposes:
- Refresh: GET /api/counter
- Increment: POST /api/counter/increment

## Flutter app (flutter_solar_terrain_analytics)

Project name must be lowercase with underscores. Create the Flutter app inside `frontend/`:

```
cd frontend
flutter create --org com.solarterrain --project-name flutter_solar_terrain_analytics flutter_solar_terrain_analytics
```

Then add dependency and code:
- Edit `frontend/flutter_solar_terrain_analytics/pubspec.yaml` and add:
  `http: ^1.2.2` under dependencies.
- Replace `lib/main.dart` with the app provided in this README section below.

Run it:

- Mobile (Android emulator):
  - Backend at `http://10.0.2.2:8081`.
  - Commands:

```
cd frontend\flutter_solar_terrain_analytics
flutter pub get
flutter run
```

- Desktop (Windows):
  - Enable once: `flutter config --enable-windows-desktop`
  - Use `http://localhost:8081`

- Web:
  - `flutter run -d chrome` (may require CORS allowances)

In the app you can edit the base URL at the top.

Main Dart example (paste into `lib/main.dart`):

```
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const CounterApp());

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Solar Terrain Analytics', theme: ThemeData(useMaterial3: true), home: const CounterHome());
  }
}

class CounterHome extends StatefulWidget {
  const CounterHome({super.key});
  @override
  State<CounterHome> createState() => _CounterHomeState();
}

class _CounterHomeState extends State<CounterHome> {
  String baseUrl = 'http://10.0.2.2:8081';
  int? count;
  String status = 'Idle';
  bool loading = false;

  Uri _uri(String path) => Uri.parse('${baseUrl.replaceAll(RegExp(r'/+


$'), '')}$path');

  Future<void> _refresh() async {
    setState(() { loading = true; status = 'Loading…'; });
    try {
      final res = await http.get(_uri('/api/counter'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      setState(() { count = data['count'] as int; status = 'OK'; });
    } catch (e) { setState(() { status = 'Error: $e'; }); }
    finally { setState(() { loading = false; }); }
  }

  Future<void> _increment() async {
    setState(() { loading = true; status = 'Incrementing…'; });
    try {
      final res = await http.post(_uri('/api/counter/increment'));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final data = json.decode(res.body) as Map<String, dynamic>;
      setState(() { count = data['count'] as int; status = 'Incremented'; });
    } catch (e) { setState(() { status = 'Error: $e'; }); }
    finally { setState(() { loading = false; }); }
  }

  @override
  void initState() { super.initState(); _refresh(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solar Terrain Analytics')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Backend base URL'),
          Row(children: [
            Expanded(child: TextFormField(initialValue: baseUrl, onChanged: (v) => baseUrl = v, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'http://localhost:8081'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: loading ? null : _refresh, child: const Text('Refresh')),
          ]),
          const SizedBox(height: 24),
          Center(child: Text(count?.toString() ?? '—', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: loading ? null : _increment, icon: const Icon(Icons.add), label: const Text('Increment')),
          const SizedBox(height: 12),
          Text(status, style: TextStyle(color: status.startsWith('Error') ? Colors.red : Colors.green)),
          const Spacer(),
          const Text('Tip: On Android emulator use http://10.0.2.2:8081 to reach localhost.'),
        ]),
      ),
    );
  }
}
```

## Backend

Start backend first:

```
cd backend/analytics-backend
mvnw.cmd spring-boot:run
```

CORS is enabled via `@CrossOrigin(origins = "*")` on the controller.
