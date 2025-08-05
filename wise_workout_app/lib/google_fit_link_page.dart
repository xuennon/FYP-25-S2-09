import 'package:flutter/material.dart';
import 'services/google_fit_service.dart';

class GoogleFitLinkPage extends StatefulWidget {
  const GoogleFitLinkPage({super.key});

  @override
  State<GoogleFitLinkPage> createState() => _GoogleFitLinkPageState();
}

class _GoogleFitLinkPageState extends State<GoogleFitLinkPage> {
  final GoogleFitService _googleFitService = GoogleFitService();
  bool _isConnecting = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    await _googleFitService.initialize();
    if (mounted) {
      setState(() {
        _isConnected = _googleFitService.isSignedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Link with Google Fit',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large heart icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 80,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Connect text
                  Text(
                    _isConnected 
                        ? 'Connected to Google Fit'
                        : 'Connect Wise workout to Google Fit',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _isConnected ? Colors.green : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_isConnected) ...[
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 40,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Connect button at bottom
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : () {
                  if (_isConnected) {
                    _handleDisconnect();
                  } else {
                    _handleGoogleFitConnection();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected 
                      ? Colors.red 
                      : const Color(0xFFFF4500), // Orange-red color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isConnecting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isConnected ? 'Disconnect' : 'Connect',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleFitConnection() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      final bool success = await _googleFitService.connectToGoogleFit();
      
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isConnected = success;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to Google Fit!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to Google Fit. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to Google Fit: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDisconnect() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Disconnect from Google Fit'),
          content: const Text('Are you sure you want to disconnect from Google Fit? You will no longer sync fitness data.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                setState(() {
                  _isConnecting = true;
                });

                try {
                  await _googleFitService.disconnect();
                  
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                      _isConnected = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully disconnected from Google Fit'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isConnecting = false;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error disconnecting: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
