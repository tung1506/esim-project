import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_esim/flutter_esim.dart';
import 'webview_esim.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSupportESim = false;
  final _flutterEsimPlugin = FlutterEsim();
  final _activationController = TextEditingController();

  // In-app logs so release APK can display progress without adb.
  final List<String> _logs = <String>[];
  StreamSubscription<dynamic>? _eventSub;

  void _addLog(String message) {
    final ts = DateTime.now().toIso8601String();
    setState(() {
      _logs.add('[$ts] $message');
      if (_logs.length > 500) {
        _logs.removeRange(0, _logs.length - 500);
      }
    });
  }

  // Open WebView
  void _openWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WebViewEsimPage(
          initialUrl: 'http://10.0.2.2:3000/esim_purchase.html',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    
    // Add initial log after first frame to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog('App started');
    });
    
    initPlatformState();

    _eventSub = _flutterEsimPlugin.onEvent.listen(
      (event) {
        _addLog('EVENT: $event');
      },
      onError: (e, st) {
        _addLog('EVENT_ERROR: $e');
      },
    );
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    bool isSupportESim;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      isSupportESim = await _flutterEsimPlugin.isSupportESim(null);
    } on PlatformException {
      isSupportESim = false;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _isSupportESim = isSupportESim;
    });
    _addLog('isSupportESim = $isSupportESim');
  }

  Future<void> installEsim() async {
    final activationCode = _activationController.text.trim();
    
    if (activationCode.isEmpty) {
      _addLog('Empty activation code');
      return;
    }

    _addLog('Installing eSIM...');
    _addLog('Activation code length: ${activationCode.length}');

    try {
      await _flutterEsimPlugin.installEsimProfile(activationCode);
      _addLog('installEsimProfile() invoked');
    } on PlatformException catch (e) {
      _addLog('PlatformException: ${e.code} ${e.message} ${e.details}');
    } catch (e) {
      _addLog('Exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app v2'),
          actions: [
            IconButton(
              tooltip: 'Clear logs',
              onPressed: () => setState(_logs.clear),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // WebView Button
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openWebView,
                    icon: const Icon(Icons.web),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                    label: const Text(
                      'Open WebView (localhost:3000)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(),
              ),
              
              // Activation code input
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _activationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Activation Code',
                    hintText: 'LPA:1\$<sm-dp+>\$<code>',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // Status and Install button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('isSupportESim: $_isSupportESim')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: installEsim,
                      child: const Text('Install eSIM'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // Logs
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'Logs will appear here...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _logs.length,
                          itemBuilder: (context, i) {
                            return SelectableText(
                              _logs[i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
