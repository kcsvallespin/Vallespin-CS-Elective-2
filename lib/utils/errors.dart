import 'package:supabase_flutter/supabase_flutter.dart';

/// True when Supabase refused the request because of Row Level Security or
/// missing privileges (as opposed to a network or validation problem).
bool isPermissionDenied(Object error) {
  if (error is PostgrestException) return error.code == '42501';
  if (error is StorageException) {
    final status = error.statusCode;
    return status == '401' ||
        status == '403' ||
        error.message.toLowerCase().contains('row-level security');
  }
  return false;
}

/// Turns any error into a short message that is safe to show to the user.
String errorMessage(Object error) {
  if (error is PostgrestException) {
    switch (error.code) {
      case '42501':
        final msg = error.message.toLowerCase();
        // Raw RLS/privilege errors get a friendly message; custom messages
        // raised by our own database functions are shown as-is.
        if (msg.contains('row-level security') ||
            msg.contains('permission denied')) {
          return "You don't have permission to do that.";
        }
        return error.message;
      case 'PGRST116':
        return 'That record was not found, or you are not allowed to change it.';
      case '23503':
        return 'This is still used by other records, so it cannot be deleted.';
      case '23505':
        return 'That name is already taken.';
    }
    return error.message;
  }
  if (error is AuthException) return error.message;
  if (error is StorageException) {
    return isPermissionDenied(error)
        ? "You don't have permission to change images."
        : 'Image upload failed: ${error.message}';
  }
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('Failed to fetch') ||
      text.contains('ClientException')) {
    return 'Could not reach the server. Check your connection and try again.';
  }
  return text;
}
