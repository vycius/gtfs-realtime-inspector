extension StringExtensions on String {
  String? emptyToNull() {
    if (isEmpty) {
      return null;
    } else {
      return this;
    }
  }
}
