import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/db_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _settingsService = SettingsService();

  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '3306');
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dbnameCtrl = TextEditingController();

  bool _loading = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _settingsService.loadAll();
    _hostCtrl.text = s['host']!;
    _portCtrl.text = s['port']!;
    _userCtrl.text = s['user']!;
    _passwordCtrl.text = s['password']!;
    _dbnameCtrl.text = s['dbname']!;
    setState(() => _loading = false);
  }

  Future<void> _save({bool popAfter = true}) async {
    if (!_formKey.currentState!.validate()) return;
    await _settingsService.saveAll(
      host: _hostCtrl.text.trim(),
      port: _portCtrl.text.trim(),
      user: _userCtrl.text.trim(),
      password: _passwordCtrl.text,
      dbname: _dbnameCtrl.text.trim(),
    );
    if (popAfter && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final db = DbService();
    try {
      await db.connect(DbConfig(
        host: _hostCtrl.text.trim(),
        port: int.parse(_portCtrl.text.trim()),
        user: _userCtrl.text.trim(),
        password: _passwordCtrl.text,
        dbname: _dbnameCtrl.text.trim(),
      ));
      _testOk = true;
      _testResult = 'Connected successfully.';
    } catch (e) {
      _testOk = false;
      _testResult = 'Connection failed: $e';
    } finally {
      await db.close();
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Database Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(labelText: 'Host / IP address'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(labelText: 'Port'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v.trim()) == null) ? 'Enter a valid port' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dbnameCtrl,
                    decoration: const InputDecoration(labelText: 'Database name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_testResult != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _testResult!,
                        style: TextStyle(color: _testOk ? Colors.green[700] : Colors.red[700]),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _testConnection,
                          child: _testing
                              ? const SizedBox(
                                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Test connection'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _save(),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
