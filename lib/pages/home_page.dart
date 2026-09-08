import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/db_service.dart';
import '../services/settings_service.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _settingsService = SettingsService();
  final _db = DbService();
  final _barcodeCtrl = TextEditingController();
  final _barcodeFocus = FocusNode();

  Product? _product;
  String? _error;
  bool _loading = false;
  bool _connecting = true;
  String _connectionStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    final configured = await _settingsService.isConfigured();
    if (!configured) {
      await _openSettings();
      return;
    }
    await _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _connectionStatus = 'Connecting...';
    });
    final s = await _settingsService.loadAll();
    try {
      await _db.connect(DbConfig(
        host: s['host']!,
        port: int.tryParse(s['port']!) ?? 3306,
        user: s['user']!,
        password: s['password']!,
        dbname: s['dbname']!,
      ));
      setState(() {
        _connecting = false;
        _connectionStatus = 'Connected';
      });
      _focusBarcodeField();
    } catch (e) {
      setState(() {
        _connecting = false;
        _connectionStatus = 'Connection failed: $e';
      });
    }
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (saved == true) {
      await _connect();
    } else {
      _focusBarcodeField();
    }
  }

  void _focusBarcodeField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _barcodeFocus.requestFocus();
    });
  }

  Future<void> _onBarcodeSubmitted(String value) async {
    final barcode = value.trim();
    _barcodeCtrl.clear();
    if (barcode.isEmpty) {
      _focusBarcodeField();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _product = null;
    });

    try {
      final product = await _db.lookupBarcode(barcode);
      setState(() {
        _product = product;
        _error = product == null ? 'No product found for barcode "$barcode".' : null;
      });
    } catch (e) {
      setState(() => _error = 'Lookup failed: $e');
    } finally {
      setState(() => _loading = false);
      _focusBarcodeField();
    }
  }

  @override
  void dispose() {
    _db.close();
    _barcodeCtrl.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Database settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: GestureDetector(
        // Any tap refocuses the hidden scan field, since a kiosk touchscreen
        // click could otherwise steal focus away from the scanner input.
        onTap: _focusBarcodeField,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            if (_connecting || _connectionStatus != 'Connected')
              Container(
                width: double.infinity,
                color: _connecting ? Colors.blueGrey[50] : Colors.red[50],
                padding: const EdgeInsets.all(8),
                child: Text(
                  _connectionStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _connecting ? Colors.blueGrey[800] : Colors.red[800]),
                ),
              ),
            // Visible barcode field so the operator can also type/paste a
            // code manually, but it's what a USB/serial "keyboard wedge"
            // scanner types into as well (scan -> digits -> Enter).
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _barcodeCtrl,
                focusNode: _barcodeFocus,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Scan barcode',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _onBarcodeSubmitted,
                textInputAction: TextInputAction.done,
              ),
            ),
            Expanded(
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : _error != null
                        ? Text(
                            _error!,
                            style: const TextStyle(fontSize: 20, color: Colors.red),
                            textAlign: TextAlign.center,
                          )
                        : _product == null
                            ? const Text(
                                'Scan a barcode to see the price',
                                style: TextStyle(fontSize: 20, color: Colors.grey),
                              )
                            : _ProductDisplay(product: _product!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDisplay extends StatelessWidget {
  final Product product;
  const _ProductDisplay({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (product.unit.isNotEmpty)
          Text(product.unit, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 24),
        Text(
          '${product.retailPrice.toStringAsFixed(2)} ${product.currency}',
          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
  }
}
