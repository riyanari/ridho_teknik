class ApiResponse<T> {
  final String message;
  final List<T> data;
  final int? total;
  final int? currentPage;
  final int? lastPage;

  ApiResponse({
    required this.message,
    required this.data,
    this.total,
    this.currentPage,
    this.lastPage,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    return ApiResponse<T>(
      message: json['message'] ?? 'OK',
      data: (json['data'] as List?)?.map((e) => fromJson(e)).toList() ?? [],
      total: json['total'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
    );
  }
}