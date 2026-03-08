class ErrorMessageHelper {
  /// Converts technical error messages to user-friendly messages
  static String getUserFriendlyMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    // Network/connectivity errors
    if (lowerError.contains('socketexception') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('nodename nor servname provided') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('clientexception')) {
      return 'No internet connection. Your data is saved locally and will sync when you\'re back online.';
    }

    // Supabase/Auth errors
    if (lowerError.contains('supabase') ||
        lowerError.contains('postgrest') ||
        lowerError.contains('jwt')) {
      return 'Unable to connect to server. Working in offline mode.';
    }

    // Timeout errors
    if (lowerError.contains('timeout')) {
      return 'Connection timed out. Please check your internet and try again.';
    }

    // Permission/Auth errors
    if (lowerError.contains('unauthorized') ||
        lowerError.contains('permission denied')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Email already exists
    if (lowerError.contains('duplicate') || 
        lowerError.contains('already exists') ||
        lowerError.contains('unique violation')) {
      return 'This email is already registered. Please use a different email or login.';
    }

    // Invalid email
    if (lowerError.contains('invalid email') ||
        lowerError.contains('invalid_credentials')) {
      return 'Please enter a valid email address.';
    }

    // Weak password
    if (lowerError.contains('password') && 
        (lowerError.contains('too short') || 
         lowerError.contains('weak'))) {
      return 'Password is too weak. Please use a stronger password (at least 6 characters).';
    }

    // Not found errors
    if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'The requested data was not found.';
    }

    // Missing profiles table error (migration not applied)
    if (lowerError.contains('relation') && lowerError.contains('profiles')) {
      return 'Database setup incomplete. Please contact support or check the setup guide.';
    }

    // Generic database errors
    if (lowerError.contains('database') || lowerError.contains('sql')) {
      return 'A database error occurred. Please try again.';
    }

    // If no specific pattern matches, check if it's a generic exception message
    if (errorMessage.startsWith('Exception:')) {
      final cleanMessage = errorMessage.replaceFirst('Exception:', '').trim();
      // Try to extract the actual message after "Failed to"
      if (cleanMessage.contains('Failed to')) {
        return cleanMessage;
      }
    }

    // Return original if no pattern matches and it's already user-friendly
    if (errorMessage.length < 100 && !errorMessage.contains('Exception')) {
      return errorMessage;
    }

    // Default fallback
    return 'An unexpected error occurred. Please try again.';
  }

  /// Checks if the error is network-related
  static bool isNetworkError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    return lowerError.contains('socketexception') ||
        lowerError.contains('failed host lookup') ||
        lowerError.contains('network') ||
        lowerError.contains('clientexception') ||
        lowerError.contains('timeout');
  }
}
