import 'package:uuid/uuid.dart';

class UUID {
  static final Uuid _uuid = Uuid();
  
  /// Generate a random UUID v4
  static String generate() {
    return _uuid.v4();
  }
}