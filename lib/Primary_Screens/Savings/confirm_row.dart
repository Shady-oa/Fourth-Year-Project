/// Simple data class used by the savings confirmation bottom sheet.
class ConfirmRow {
  final String label;
  final String value;
  final bool highlight;
  const ConfirmRow(this.label, this.value, {this.highlight = false});
}
