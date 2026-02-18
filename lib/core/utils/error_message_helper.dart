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

    // Not found errors
    if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'The requested data was not found.';
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
