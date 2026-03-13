import 'package:flutter/material.dart';
import '../models/class_session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'check_in_screen.dart';
import 'finish_class_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClassSession> _sessions = [];

  ClassSession? get _activeSession {
    final active = _sessions
        .where((s) => s.status == SessionStatus.checkedIn)
        .toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return active.isEmpty ? null : active.first;
  }

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
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 980;
    final isTablet = width >= 700;
    final horizontalPadding = isWide ? 28.0 : (isTablet ? 22.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Class'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh sessions',
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 28, right: 20),
                          child: _buildHeaderAndActions(isTablet),
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: _buildHistorySection(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            isTablet ? 8 : 0, 24, isTablet ? 8 : 0, 12),
                        child: _buildHeaderAndActions(isTablet),
                      ),
                      Expanded(child: _buildHistorySection()),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndActions(bool isTablet) {
    return Column(
      children: [
        Icon(Icons.school,
            size: isTablet ? 72 : 64, color: AppColors.primaryRed),
        const SizedBox(height: 12),
        Text(
          'Smart Class App',
          style: TextStyle(
            fontSize: isTablet ? 24 : 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: Text(
              _activeSession == null ? 'Check In' : 'Resume Active Session',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed:
                _activeSession == null ? () => _navigate(const CheckInScreen()) : null,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Finish Class'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16),
              backgroundColor:
                  _activeSession == null ? AppColors.white : AppColors.cream,
            ),
            onPressed: _activeSession == null
                ? null
                : () => _navigate(const FinishClassScreen()),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _activeSession == null
              ? 'No active session. Start with Check In.'
              : 'Active session found. Please finish it before a new check-in.',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: AppColors.softGold),
              const SizedBox(width: 6),
              Text(
                'Session History (${_sessions.length})',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText),
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
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final s = _sessions[index];
                    final isCompleted = s.status == SessionStatus.completed;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCompleted ? AppColors.cream : AppColors.lightGrayBg,
                          child: Icon(
                            isCompleted ? Icons.check_circle : Icons.pending,
                            color: isCompleted
                                ? AppColors.softGold
                                : AppColors.primaryRed,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          s.studentId,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Check-in: ${_formatDate(s.checkInTime)}\n'
                          'Finish: ${s.finishTime != null ? _formatDate(s.finishTime!) : '-'}\n'
                          'Mood: ${s.mood}/5\n'
                          'Learned: ${_shorten(s.learnedToday)}',
                        ),
                        isThreeLine: false,
                        trailing: Chip(
                          label: Text(
                            isCompleted ? 'Done' : 'Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompleted
                                  ? AppColors.softGold
                                  : AppColors.darkRed,
                            ),
                          ),
                          backgroundColor:
                              isCompleted ? AppColors.cream : AppColors.lightGrayBg,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
      '${_p(dt.hour)}:${_p(dt.minute)}';

  String _shorten(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value.length <= 22 ? value : '${value.substring(0, 22)}...';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
