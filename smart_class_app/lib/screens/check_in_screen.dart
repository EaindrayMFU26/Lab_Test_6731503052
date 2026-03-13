import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../models/class_session.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _previousTopicController = TextEditingController();
  final _expectedTopicController = TextEditingController();

  Position? _position;
  bool _locationLoading = false;

  String? _qrCode;
  bool _scanningQr = false;

  int _mood = 3; // 1–5

  bool _submitting = false;

  // Validation error flags (shown after a failed submit attempt)
  bool _locationMissing = false;
  bool _qrMissing = false;

  static const _moodOptions = [
    (value: 1, emoji: '😡', label: 'Very Negative'),
    (value: 2, emoji: '🙁', label: 'Negative'),
    (value: 3, emoji: '😐', label: 'Neutral'),
    (value: 4, emoji: '🙂', label: 'Positive'),
    (value: 5, emoji: '😄', label: 'Very Positive'),
  ];

  @override
  void dispose() {
    _studentIdController.dispose();
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
  }

  // ── Location ─────────────────────────────────────────────────────────────

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

    setState(() => _submitting = true);
    try {
      final session = ClassSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: _studentIdController.text.trim(),
        checkInTime: DateTime.now(),
        checkInLat: _position!.latitude,
        checkInLng: _position!.longitude,
        checkInQr: _qrCode!,
        previousTopic: _previousTopicController.text.trim(),
        expectedTopic: _expectedTopicController.text.trim(),
        mood: _mood,
      );

      await StorageService.saveSession(session);

      // Do cloud sync in background so navigation is instant after local save.
      unawaited(
        FirestoreService.saveSession(session)
            .timeout(const Duration(seconds: 3))
            .catchError((_) {}),
      );

      if (mounted) {
        _showSnack('Check-in successful!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack('Check-in failed: $e', isError: true);
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
          // Framing overlay
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
        title: const Text('Check In to Class'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Step 1 – Student ID ────────────────────────────────────
              _sectionHeader('1. Student ID', Icons.badge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  hintText: 'e.g. 6731503052',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Student ID is required' : null,
              ),

              const SizedBox(height: 20),

              // ── Step 2 – GPS Location ─────────────────────────────────
              _sectionHeader('2. GPS Location', Icons.location_on),
              const SizedBox(height: 8),
              _locationCard(),

              const SizedBox(height: 20),

              // ── Step 3 – QR Code ──────────────────────────────────────
              _sectionHeader('3. Class QR Code', Icons.qr_code_scanner),
              const SizedBox(height: 8),
              _qrCard(),

              const SizedBox(height: 20),

              // ── Step 4 – Reflection ───────────────────────────────────
              _sectionHeader('4. Learning Reflection', Icons.menu_book),
              const SizedBox(height: 8),
              TextFormField(
                controller: _previousTopicController,
                decoration: const InputDecoration(
                  labelText: 'Topic covered in the previous class',
                  hintText: 'e.g. Introduction to Flutter widgets',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history_edu),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expectedTopicController,
                decoration: const InputDecoration(
                  labelText: 'Topic you expect to learn today',
                  hintText: 'e.g. State management with Provider',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),

              const SizedBox(height: 20),

              // ── Step 5 – Mood ─────────────────────────────────────────
              _sectionHeader('5. Mood Before Class', Icons.mood),
              const SizedBox(height: 8),
              _moodSelector(),

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
                label: Text(_submitting ? 'Saving…' : 'Submit Check-In'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
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
                      color: captured ? Colors.green.shade800 : Colors.grey,
                    ),
                  ),
                  if (captured)
                    Text(
                      'Lat: ${_position!.latitude.toStringAsFixed(6)}\n'
                      'Lng: ${_position!.longitude.toStringAsFixed(6)}\n'
                      'Accuracy: ±${_position!.accuracy.toStringAsFixed(1)} m',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  if (_locationMissing)
                    const Text('Required – tap Get Location',
                        style:
                            TextStyle(fontSize: 12, color: Colors.red)),
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
                        style:
                            TextStyle(fontSize: 12, color: Colors.red)),
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

  Widget _moodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: _moodOptions.map((opt) {
            return RadioListTile<int>(
              value: opt.value,
              groupValue: _mood,
              title: Text('${opt.emoji}  ${opt.label}'),
              dense: true,
              onChanged: (v) => setState(() => _mood = v!),
            );
          }).toList(),
        ),
      ),
    );
  }
}
