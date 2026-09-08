import 'package:mysql1/mysql1.dart';
import '../models/product.dart';

class DbConfig {
  final String host;
  final int port;
  final String user;
  final String password;
  final String dbname;

  DbConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.dbname,
  });
}

/// Barcode -> price lookup, reusing the exact query recovered from the
/// original Android app (tbl_item_barcode / tbl_item / tbl_currency,
/// with func_get_item_cost2 for the cost/price tiers). That stored
/// function and schema must already exist in the target MySQL database.
class DbService {
  MySqlConnection? _conn;
  DbConfig? _config;

  static const String _lookupQuery = '''
    SELECT tbl_item.it_id AS ItemID,
           it_name AS NAME,
           it_unit_name AS Unit,
           it_un_price_sell_a AS RetailPrice,
           it_un_price_sell_b AS WholesalePrice,
           it_un_price_sell_c AS HalfWholesalePrice,
           it_un_price_sell_d AS ExportPrice,
           it_un_price_sell_e AS ConsumerPrice,
           cur_lst_code AS Currency
    FROM tbl_item_barcode
    INNER JOIN tbl_item
        ON (it_item_id = it_barcode_item_id AND it_unit_id = it_barcode_unit_id)
    INNER JOIN tbl_currency
        ON (it_id_currency = cur_lst_id)
    WHERE it_barcode_value = ?
    LIMIT 1
  ''';

  Future<void> connect(DbConfig config) async {
    await close();
    _config = config;
    final settings = ConnectionSettings(
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      db: config.dbname,
      timeout: const Duration(seconds: 8),
    );
    _conn = await MySqlConnection.connect(settings);
  }

  Future<void> close() async {
    try {
      await _conn?.close();
    } catch (_) {
      // ignore close errors
    }
    _conn = null;
  }

  bool get isConnected => _conn != null;

  /// Looks up a product by barcode. Reconnects automatically once if the
  /// connection has dropped (kiosk devices often sit idle for a long time
  /// between scans, which can time out the MySQL connection).
  Future<Product?> lookupBarcode(String barcode) async {
    if (_conn == null || _config == null) {
      throw StateError('Not connected. Call connect() first.');
    }

    Future<Results> runQuery() => _conn!.query(_lookupQuery, [barcode.trim()]);

    Results results;
    try {
      results = await runQuery();
    } catch (_) {
      // Attempt one reconnect + retry in case the connection went stale.
      await connect(_config!);
      results = await runQuery();
    }

    if (results.isEmpty) return null;
    final row = results.first.fields;
    return Product.fromRow(row);
  }
}
