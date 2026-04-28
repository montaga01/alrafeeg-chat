class ApiResponse<T> {
  final bool success;
  final String? error;
  final T? data;

  ApiResponse({
    required this.success,
    this.error,
    this.data,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(success: true, data: data);
  }

  factory ApiResponse.failure(String error) {
    return ApiResponse(success: false, error: error);
  }
}
