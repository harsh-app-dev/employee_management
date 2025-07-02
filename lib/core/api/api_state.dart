enum ApiStatus { initial, loading, success, error }

class ApiState<T> {
  final ApiStatus status; // Represents the current status (e.g., loading)
  final T? data; // Generic data for the success state
  final String? error; // Error message for the error state

  ApiState._({required this.status, this.data, this.error});

  // Initial state
  factory ApiState.initial() {
    return ApiState._(status: ApiStatus.initial);
  }

  // Loading state
  factory ApiState.loading() {
    return ApiState._(status: ApiStatus.loading);
  }

  // Success state
  factory ApiState.success(T data) {
    return ApiState._(status: ApiStatus.success, data: data);
  }

  // Error state
  factory ApiState.error(String message) {
    return ApiState._(status: ApiStatus.error, error: message);
  }

  // Helper Methods
  bool get isInitial => status == ApiStatus.initial;

  bool get isLoading => status == ApiStatus.loading;

  bool get isSuccess => status == ApiStatus.success;

  bool get isError => status == ApiStatus.error;

  @override
  String toString() {
    return 'ApiState(status: $status, data: $data, error: $error)';
  }
}

