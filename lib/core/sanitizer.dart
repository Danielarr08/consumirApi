String sanitize(String input) {
  final cleaned = input
      .replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '')
      .trim();
  return cleaned.length > 80 ? '${cleaned.substring(0, 80)}…' : cleaned;
}

bool isValidCity(String input) {
  final re = RegExp(r"^[\p{L} .,'-]{1,40}$", unicode: true);
  return re.hasMatch(input.trim());
}
