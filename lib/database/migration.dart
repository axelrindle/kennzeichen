import 'package:sqflite/sqflite.dart';

/// Represents a single migration.
abstract class Migration {

  /// Called when migrating.
  Future<void> up(Transaction txn);

  /// Called when rolling back.
  Future<void> down(Transaction txn);

}
