import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class DeepLinkTesterPage extends StatefulWidget {
  const DeepLinkTesterPage({super.key});

  @override
  State<DeepLinkTesterPage> createState() => _DeepLinkTesterPageState();
}

class _DeepLinkTesterPageState extends State<DeepLinkTesterPage> {
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with a sample Firebase hosting link format
    _linkController.text = 'https://fyp-25-s2-09.web.app/join/SAMPLE_TOKEN';
  }

  void _testDeepLink() {
    final link = _linkController.text.trim();
    if (link.isNotEmpty) {
      print('🧪 Testing deep link: $link');
      
      // Call the global deep link handler
      handleGlobalDeepLink(link);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Testing deep link: $link'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a team invite link to test'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testSampleLinks() {
    final sampleLinks = [
      'https://fyp-25-s2-09.web.app/join/sample_token_123',
      'https://wiseworkout.app/join/sample_token_456',
      'wiseworkout://team/sample_token_789',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Sample Links'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sampleLinks.map((link) => ListTile(
            title: Text(
              link,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                Navigator.of(context).pop();
                _linkController.text = link;
                _testDeepLink();
              },
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Link Tester'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deep Link Testing Tool',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test team invite links to see if they properly navigate to the correct page based on membership status.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Enter Team Invite Link:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                hintText: 'https://fyp-25-s2-09.web.app/join/TOKEN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _linkController.clear(),
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testDeepLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Test Deep Link',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _testSampleLinks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  child: const Text('Sample Links'),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              'Supported Link Formats:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildLinkFormat('Firebase Hosting', 'https://fyp-25-s2-09.web.app/join/TOKEN'),
            _buildLinkFormat('Wise Workout App', 'https://wiseworkout.app/join/TOKEN'),
            _buildLinkFormat('Custom Scheme', 'wiseworkout://team/TOKEN'),
            _buildLinkFormat('Legacy Format', 'https://wiseworkout.app/join-team?token=TOKEN'),
            
            const SizedBox(height: 30),
            
            const Text(
              'Expected Behavior:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildBehaviorItem('✅ Already a member', 'Navigate to TeamDetailsPage'),
            _buildBehaviorItem('🆕 Not a member', 'Navigate to DiscoveredTeamDetailsPage'),
            _buildBehaviorItem('❌ Invalid link', 'Show error message'),
            _buildBehaviorItem('⚠️ Not logged in', 'Redirect to login, then process link'),
            
            const Spacer(),
            
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'This tool simulates clicking on team invite links from external apps like WhatsApp, Telegram, etc.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkFormat(String title, String format) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  format,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: format));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Format copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorItem(String condition, String behavior) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black),
                children: [
                  TextSpan(
                    text: condition,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ': '),
                  TextSpan(
                    text: behavior,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}
