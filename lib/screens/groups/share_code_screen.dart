import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../services/group_service.dart';

class ShareCodeScreen extends ConsumerStatefulWidget {
  const ShareCodeScreen({super.key});

  @override
  ConsumerState<ShareCodeScreen> createState() => _ShareCodeScreenState();
}

class _ShareCodeScreenState extends ConsumerState<ShareCodeScreen> {
  final GroupService _groupService = GroupService();
  String? _inviteCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    final groupId = await _groupService.getUserGroupId(userId);
    if (groupId != null) {
      final code = await _groupService.getGroupCode(groupId);
      if (mounted) {
        setState(() {
          _inviteCode = code;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createGroup() async {
    setState(() => _isLoading = true);
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;

    try {
      final code = await _groupService.createGroup(userId);
      if (mounted) {
        if (code != null) {
          setState(() {
            _inviteCode = code;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Failed to create group. Check your connection or Firestore rules.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Joint Budget Group')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_inviteCode != null) ...[
                      const Text(
                        'Your Group Code',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                        child: SelectableText(
                          _inviteCode!,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _inviteCode!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied!')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Share.share(
                                  'Join my budget group using this code: $_inviteCode');
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Share this code with your partner correctly to sync your budgets.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ] else ...[
                      const Icon(Icons.group_add, size: 64, color: Colors.grey),
                      const SizedBox(height: 24),
                      const Text(
                        'Create a Joint Group',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create a group to share expenses and track budget together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _createGroup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                        ),
                        child: const Text('Create Group'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
