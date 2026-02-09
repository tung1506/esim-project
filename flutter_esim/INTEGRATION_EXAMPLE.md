# Integration Examples

## 📱 Complete Integration Examples

### Example 1: Basic eSIM Purchase Flow

```dart
// lib/pages/esim_purchase_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class ESimPurchasePage extends StatefulWidget {
  final String purchaseUrl;

  const ESimPurchasePage({
    Key? key,
    required this.purchaseUrl,
  }) : super(key: key);

  @override
  State<ESimPurchasePage> createState() => _ESimPurchasePageState();
}

class _ESimPurchasePageState extends State<ESimPurchasePage> {
  bool _isWebViewReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase eSIM'),
        actions: [
          if (_isWebViewReady)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh the page
                setState(() {});
              },
            ),
        ],
      ),
      body: FlutterEsimWebView(
        initialUrl: widget.purchaseUrl,
        
        onWebViewCreated: () {
          setState(() {
            _isWebViewReady = true;
          });
        },
        
        onPageFinished: (url) {
          print('Loaded: $url');
        },
        
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}
```

### Example 2: With Authentication (Cookies & Headers)

```dart
// lib/pages/authenticated_esim_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class AuthenticatedESimPage extends StatelessWidget {
  final String userId;
  final String authToken;
  final String purchaseUrl;

  const AuthenticatedESimPage({
    Key? key,
    required this.userId,
    required this.authToken,
    required this.purchaseUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('eSIM Purchase - User $userId'),
      ),
      body: FlutterEsimWebView(
        initialUrl: purchaseUrl,
        
        // Inject authentication cookies
        initialCookies: {
          'user_id': userId,
          'session_token': authToken,
          'device_id': 'flutter-app-${DateTime.now().millisecondsSinceEpoch}',
        },
        
        // Inject authentication headers
        initialHeaders: {
          'Authorization': 'Bearer $authToken',
          'X-User-ID': userId,
          'X-Platform': 'Flutter',
        },
        
        onWebViewCreated: () {
          print('WebView created with auth credentials');
        },
        
        onError: (error) {
          // Handle authentication errors
          if (error.contains('401') || error.contains('403')) {
            _showAuthError(context);
          }
        },
      ),
    );
  }

  void _showAuthError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Example 3: With Loading Progress and Error Handling

```dart
// lib/pages/esim_page_with_progress.dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class ESimPageWithProgress extends StatefulWidget {
  final String url;

  const ESimPageWithProgress({Key? key, required this.url}) : super(key: key);

  @override
  State<ESimPageWithProgress> createState() => _ESimPageWithProgressState();
}

class _ESimPageWithProgressState extends State<ESimPageWithProgress> {
  bool _isLoading = true;
  String? _currentUrl;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSIM Setup'),
        subtitle: _currentUrl != null ? Text(_currentUrl!, style: TextStyle(fontSize: 12)) : null,
      ),
      body: Stack(
        children: [
          FlutterEsimWebView(
            initialUrl: widget.url,
            
            onPageStarted: (url) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
                _errorMessage = null;
              });
            },
            
            onPageFinished: (url) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
              });
            },
            
            onError: (error) {
              setState(() {
                _isLoading = false;
                _errorMessage = error;
              });
            },
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          
          // Error overlay
          if (_errorMessage != null)
            Container(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Page',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Example 4: Check eSIM Support Before Opening WebView

```dart
// lib/pages/esim_check_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class ESimCheckPage extends StatefulWidget {
  final String purchaseUrl;

  const ESimCheckPage({Key? key, required this.purchaseUrl}) : super(key: key);

  @override
  State<ESimCheckPage> createState() => _ESimCheckPageState();
}

class _ESimCheckPageState extends State<ESimCheckPage> {
  bool _isChecking = true;
  bool _isSupported = false;
  String _message = '';
  String _deviceModel = '';

  @override
  void initState() {
    super.initState();
    _checkESimSupport();
  }

  Future<void> _checkESimSupport() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final plugin = FlutterEsim();
      final result = await plugin.isSupportESim();

      setState(() {
        _isSupported = result['isSupported'] ?? false;
        _message = result['message'] ?? '';
        _deviceModel = result['deviceModel'] ?? '';
        _isChecking = false;
      });

      // If supported, automatically navigate to WebView
      if (_isSupported && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => _buildWebViewPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _message = 'Error checking eSIM support: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checking Device')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking eSIM support...'),
            ],
          ),
        ),
      );
    }

    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('eSIM Not Supported')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sim_card_alert, size: 64, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'eSIM Not Available',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (_deviceModel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Device: $_deviceModel',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Requirements:\n'
                  '• Android 9.0+ (SDK 28+)\n'
                  '• iOS 17.4+\n'
                  '• eSIM-capable device',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // This won't be shown as we navigate away, but kept for completeness
    return _buildWebViewPage();
  }

  Widget _buildWebViewPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase eSIM'),
        subtitle: Text(_deviceModel),
      ),
      body: FlutterEsimWebView(
        initialUrl: widget.purchaseUrl,
      ),
    );
  }
}
```

### Example 5: Production-Ready with Analytics

```dart
// lib/pages/production_esim_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esim/flutter_esim.dart';

class ProductionESimPage extends StatefulWidget {
  final String url;
  final String? userId;

  const ProductionESimPage({
    Key? key,
    required this.url,
    this.userId,
  }) : super(key: key);

  @override
  State<ProductionESimPage> createState() => _ProductionESimPageState();
}

class _ProductionESimPageState extends State<ProductionESimPage> {
  final _startTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Confirm before closing
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Purchase?'),
            content: const Text('Are you sure you want to exit the purchase process?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('eSIM Purchase'),
        ),
        body: FlutterEsimWebView(
          initialUrl: widget.url,
          
          // Only enable debug in development
          debugEnabled: kDebugMode,
          
          // Inject user tracking data
          initialCookies: widget.userId != null
              ? {'user_id': widget.userId!}
              : null,
          
          initialHeaders: {
            'X-App-Version': '1.0.0',
            'X-Platform': 'Flutter',
          },
          
          onWebViewCreated: () {
            _logAnalytics('webview_created');
          },
          
          onWebViewClosed: () {
            final duration = DateTime.now().difference(_startTime);
            _logAnalytics('webview_closed', {
              'duration_seconds': duration.inSeconds,
            });
          },
          
          onPageStarted: (url) {
            _logAnalytics('page_started', {'url': url});
          },
          
          onPageFinished: (url) {
            final loadTime = DateTime.now().difference(_startTime);
            _logAnalytics('page_finished', {
              'url': url,
              'load_time_ms': loadTime.inMilliseconds,
            });
          },
          
          onError: (error) {
            _logAnalytics('webview_error', {'error': error});
            
            // Show user-friendly error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('An error occurred. Please try again.'),
                action: SnackBarAction(
                  label: 'Reload',
                  onPressed: () {
                    setState(() {});
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _logAnalytics(String event, [Map<String, dynamic>? parameters]) {
    // Replace with your analytics service (Firebase, Mixpanel, etc.)
    debugPrint('Analytics: $event ${parameters ?? ""}');
    
    // Example: FirebaseAnalytics.instance.logEvent(
    //   name: event,
    //   parameters: parameters,
    // );
  }

  @override
  void dispose() {
    final sessionDuration = DateTime.now().difference(_startTime);
    _logAnalytics('session_ended', {
      'duration_seconds': sessionDuration.inSeconds,
    });
    super.dispose();
  }
}
```

### Example 6: Main App Integration

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/production_esim_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eSIM App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key: key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSIM Manager'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sim_card, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Welcome to eSIM Manager',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Purchase and manage your eSIM profiles',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProductionESimPage(
                        url: 'https://your-esim-provider.com/purchase',
                        userId: 'user123',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Purchase eSIM'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
```

### Example 7: Backend Integration (Node.js)

```javascript
// server.js - Example backend for eSIM purchase page
const express = require('express');
const app = express();

app.use(express.json());
app.use(express.static('public'));

// Serve the eSIM purchase page
app.get('/purchase', (req, res) => {
  // Check authentication from Flutter app cookies/headers
  const userId = req.cookies.user_id || req.headers['x-user-id'];
  const authToken = req.headers['authorization'];
  
  if (!userId || !authToken) {
    return res.status(401).send('Unauthorized');
  }
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>eSIM Purchase</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: sans-serif; padding: 20px; }
        button { padding: 12px 24px; font-size: 16px; }
      </style>
    </head>
    <body>
      <h1>Purchase eSIM</h1>
      <p>User ID: ${userId}</p>
      
      <button id="checkSupport">Check Device Support</button>
      <button id="purchaseBtn" disabled>Purchase eSIM</button>
      
      <div id="status"></div>
      
      <script>
        const statusDiv = document.getElementById('status');
        const purchaseBtn = document.getElementById('purchaseBtn');
        
        document.getElementById('checkSupport').addEventListener('click', async () => {
          try {
            const result = await window.FlutterEsimBridge.isSupportESim();
            
            if (result.isSupported) {
              statusDiv.innerHTML = '<p style="color: green;">✓ Device supports eSIM</p>';
              purchaseBtn.disabled = false;
            } else {
              statusDiv.innerHTML = '<p style="color: red;">✗ ' + result.message + '</p>';
            }
          } catch (error) {
            statusDiv.innerHTML = '<p style="color: red;">Error: ' + error.message + '</p>';
          }
        });
        
        purchaseBtn.addEventListener('click', async () => {
          // Call your backend API to generate activation code
          const response = await fetch('/api/generate-activation-code', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': '${authToken}',
            },
            body: JSON.stringify({ userId: '${userId}' }),
          });
          
          const data = await response.json();
          
          if (data.activationCode) {
            // Install eSIM
            const result = await window.FlutterEsimBridge.installEsimProfile(data.activationCode);
            
            if (result.isSuccess) {
              statusDiv.innerHTML = '<p style="color: green;">✓ eSIM installed successfully!</p>';
            } else {
              statusDiv.innerHTML = '<p style="color: red;">✗ Installation failed: ' + result.message + '</p>';
            }
          }
        });
      </script>
    </body>
    </html>
  `);
});

// API endpoint to generate activation code
app.post('/api/generate-activation-code', (req, res) => {
  const { userId } = req.body;
  
  // TODO: Integrate with your eSIM provider API
  // This is a mock response
  const activationCode = `LPA:1$smdp.example.com$activation-code-${userId}-${Date.now()}`;
  
  res.json({
    success: true,
    activationCode: activationCode,
  });
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
});
```

## 🔄 Navigation Flow Example

```dart
// Complete navigation flow from home to purchase
class AppNavigator {
  static Future<void> navigateToESimPurchase(
    BuildContext context, {
    required String purchaseUrl,
    String? userId,
    String? authToken,
  }) async {
    // 1. Check eSIM support first
    final plugin = FlutterEsim();
    final supportResult = await plugin.isSupportESim();
    
    if (!supportResult['isSupported']) {
      // Show not supported dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('eSIM Not Supported'),
          content: Text(supportResult['message'] ?? 'Device does not support eSIM'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // 2. Navigate to WebView
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProductionESimPage(
          url: purchaseUrl,
          userId: userId,
        ),
      ),
    );
    
    // 3. Handle result
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eSIM installed successfully!')),
      );
    }
  }
}

// Usage
ElevatedButton(
  onPressed: () {
    AppNavigator.navigateToESimPurchase(
      context,
      purchaseUrl: 'https://your-provider.com/purchase',
      userId: 'user123',
      authToken: 'token456',
    );
  },
  child: const Text('Purchase eSIM'),
)
```

## 🎯 Best Practices Summary

1. **Always check eSIM support** before showing purchase UI
2. **Use HTTPS URLs** in production
3. **Handle errors gracefully** with user-friendly messages
4. **Enable debug mode** only in development (`kDebugMode`)
5. **Inject authentication** via cookies/headers
6. **Log analytics events** for monitoring
7. **Confirm before closing** WebView during purchase
8. **Show loading indicators** for better UX
9. **Validate activation codes** on backend
10. **Test on real devices** (emulators don't support eSIM)

---

For more details, see [USAGE_GUIDE.md](USAGE_GUIDE.md)
