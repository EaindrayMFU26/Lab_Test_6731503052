import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../services/storage_service.dart';
import 'check_in_screen.dart';
import 'finish_class_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClassSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await StorageService.getAllSessions();
    sessions.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    setState(() => _sessions = sessions);
  }

  Future<void> _navigate(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _loadSessions(); // refresh list after returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Class Check-in'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh sessions',
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── App header + action buttons ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Column(
              children: [
                const Icon(Icons.school, size: 64, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  'Smart Class App',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Check In to Class'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _navigate(const CheckInScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Finish Class'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _navigate(const FinishClassScreen()),
                  ),
                ),
              ],
            ),
          ),

          // ── Session history ──────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.history, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Session History (${_sessions.length})',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text(
                      'No sessions yet.\nCheck in to start!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final s = _sessions[index];
                      final isCompleted =
                          s.status == SessionStatus.completed;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCompleted
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                            child: Icon(
                              isCompleted
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.blue,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            s.studentId,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_formatDate(s.checkInTime)}  •  '
                            'Mood: ${s.mood}/5\n'
                            'QR: ${s.checkInQr}',
                          ),
                          isThreeLine: true,
                          trailing: Chip(
                            label: Text(
                              isCompleted ? 'Done' : 'Active',
                              style: TextStyle(
                                fontSize: 11,
                                color: isCompleted
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                            backgroundColor: isCompleted
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
      '${_p(dt.hour)}:${_p(dt.minute)}';

  String _p(int n) => n.toString().padLeft(2, '0');
}
