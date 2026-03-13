import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../models/class_session.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _learnedController = TextEditingController();
  final _feedbackController = TextEditingController();

  Position? _position;
  bool _locationLoading = false;

  String? _qrCode;
  bool _scanningQr = false;

  bool _submitting = false;

  // Validation error flags
  bool _locationMissing = false;
  bool _qrMissing = false;

  // Active session loaded on submit
  ClassSession? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final session = await StorageService.getLatestSession();
    setState(() => _activeSession = session);
  }

  @override
  void dispose() {
    _learnedController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _position = pos;
        _locationMissing = false;
      });
    } catch (e) {
      _showSnack('Location error: $e', isError: true);
    } finally {
      setState(() => _locationLoading = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _locationMissing = _position == null;
      _qrMissing = _qrCode == null;
    });

    if (!formValid || _locationMissing || _qrMissing) return;

    // Reload in case user navigated away and back
    final session = _activeSession ?? await StorageService.getLatestSession();
    if (session == null) {
      _showSnack('No active check-in session found. Please check in first.',
          isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      session.finishTime = DateTime.now();
      session.finishLat = _position!.latitude;
      session.finishLng = _position!.longitude;
      session.finishQr = _qrCode!;
      session.learnedToday = _learnedController.text.trim();
      session.feedback = _feedbackController.text.trim();
      session.status = SessionStatus.completed;

      await StorageService.updateSession(session);

      // Do cloud sync in background so navigation is instant after local save.
      unawaited(
        FirestoreService.updateSession(session)
            .timeout(const Duration(seconds: 3))
            .catchError((_) {}),
      );

      if (mounted) {
        _showSnack('Class finished successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Finish class failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : null,
    ));
  }

  // ── QR Scanner page ───────────────────────────────────────────────────────

  Widget _buildQrScanner() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Class QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _scanningQr = false),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final raw = capture.barcodes.firstOrNull?.rawValue;
              if (raw != null) {
                setState(() {
                  _qrCode = raw;
                  _qrMissing = false;
                  _scanningQr = false;
                });
              }
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Point the camera at the class QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main form ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_scanningQr) return _buildQrScanner();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish Class'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Active session banner ─────────────────────────────────
              _activeSessionBanner(),

              const SizedBox(height: 20),

              // ── Step 1 – GPS Location ─────────────────────────────────
              _sectionHeader('1. GPS Location', Icons.location_on),
              const SizedBox(height: 8),
              _locationCard(),

              const SizedBox(height: 20),

              // ── Step 2 – QR Code ──────────────────────────────────────
              _sectionHeader('2. Class QR Code', Icons.qr_code_scanner),
              const SizedBox(height: 8),
              _qrCard(),

              const SizedBox(height: 20),

              // ── Step 3 – Learning Reflection ──────────────────────────
              _sectionHeader('3. Learning Reflection', Icons.menu_book),
              const SizedBox(height: 8),
              TextFormField(
                controller: _learnedController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What did you learn today?',
                  hintText: 'Summarise the main topic or concept covered…',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.auto_stories),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // ── Step 4 – Feedback ─────────────────────────────────────
              _sectionHeader('4. Feedback', Icons.feedback_outlined),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Feedback about the class or instructor',
                  hintText: 'What went well? Any suggestions?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.rate_review_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────────────
              ElevatedButton.icon(
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_submitting ? 'Saving…' : 'Finish Class'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _activeSessionBanner() {
    if (_activeSession == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No active check-in found.\nPlease check in to a class first.',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      );
    }

    final s = _activeSession!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 6),
              Text('Active Session',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Student: ${s.studentId}'),
          Text('Checked in: ${_formatDate(s.checkInTime)}'),
          Text('QR: ${s.checkInQr}'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }

  Widget _locationCard() {
    final captured = _position != null;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _locationMissing
              ? Colors.red
              : captured
                  ? Colors.green
                  : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              captured ? Icons.location_on : Icons.location_off,
              color: captured ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    captured ? 'Location captured' : 'Location not obtained',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          captured ? Colors.green.shade800 : Colors.grey,
                    ),
                  ),
                  if (captured)
                    Text(
                      'Lat: ${_position!.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${_position!.longitude.toStringAsFixed(6)}\n'
                      'Accuracy: ±${_position!.accuracy.toStringAsFixed(1)} m',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black87),
                    ),
                  if (_locationMissing)
                    const Text('Required – tap Get Location',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: _locationLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 16),
              label: Text(captured ? 'Refresh' : 'Get Location'),
              onPressed: _locationLoading ? null : _getLocation,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrCard() {
    final scanned = _qrCode != null;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _qrMissing
              ? Colors.red
              : scanned
                  ? Colors.green
                  : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              scanned ? Icons.qr_code : Icons.qr_code_scanner,
              color: scanned ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanned ? 'QR code scanned' : 'QR code not scanned',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scanned ? Colors.green.shade800 : Colors.grey,
                    ),
                  ),
                  if (scanned)
                    Text(
                      _qrCode!,
                      style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (_qrMissing)
                    const Text('Required – tap Scan QR',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: Text(scanned ? 'Re-scan' : 'Scan QR'),
              onPressed: () => setState(() => _scanningQr = true),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
      '${_p(dt.hour)}:${_p(dt.minute)}';

  String _p(int n) => n.toString().padLeft(2, '0');
}
