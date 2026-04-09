class LocationState {
  final String? address;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.address,
    this.isLoading = false,
    this.error,
  });
}
