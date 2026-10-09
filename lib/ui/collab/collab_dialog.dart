import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/collab_service.dart';

class CollabDialog extends StatefulWidget {
  const CollabDialog({super.key});

  @override
  State<CollabDialog> createState() => _CollabDialogState();
}

class _CollabDialogState extends State<CollabDialog> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _roomCodeCtrl = TextEditingController();
  final TextEditingController _hostIpCtrl = TextEditingController(text: '192.168.1.100');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _roomCodeCtrl.dispose();
    _hostIpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collab = CollabService.instance;

    return Dialog(
      backgroundColor: const Color(0xFFFBF8F2), // Warm Ivory
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2DCD0), width: 1.0),
      ),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.users, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAN Whiteboard Collaboration',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B1C1E),
                      ),
                    ),
                    Text(
                      'Real-time P2P inking sync over local classroom Wi-Fi',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2DCD0), height: 28),

            // Connected Active State Banner
            if (collab.isConnected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.wifi, size: 18, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Text(
                          'Live Session Active: ${collab.roomCode}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Role: ${collab.role == CollabRole.host ? 'Teacher Host' : 'Connected Student'} (${collab.connectedPeersCount} devices synced)',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF166534)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        collab.disconnect();
                        setState(() {});
                      },
                      icon: const Icon(LucideIcons.logOut, size: 14),
                      label: const Text('Leave Session', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Tabs for Host vs Join
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAE1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: const Color(0xFF1B1C1E),
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Host Whiteboard'),
                    Tab(text: 'Join Room'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // Host Tab
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Host a synchronized whiteboard session on your local network.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4A4E57)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Student tablets on the same Wi-Fi can join instantly using the room code.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF9CA3AF)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final code = await collab.startHosting();
                            if (!mounted) return;
                            setState(() {});
                            Clipboard.setData(ClipboardData(text: code));
                            messenger.showSnackBar(
                              SnackBar(content: Text('Room $code started and copied to clipboard!')),
                            );
                          },
                          icon: const Icon(LucideIcons.radio, size: 16),
                          label: const Text('Start Hosting Session', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B1C1E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),

                    // Join Tab
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter 6-Digit Room Code',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A4E57)),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _roomCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'e.g. KEST-4921',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2DCD0))),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final code = _roomCodeCtrl.text.trim();
                            if (code.isNotEmpty) {
                              await collab.joinSession(roomCode: code, hostAddress: _hostIpCtrl.text.trim());
                              setState(() {});
                            }
                          },
                          icon: const Icon(LucideIcons.logIn, size: 16),
                          label: const Text('Connect to Room', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
