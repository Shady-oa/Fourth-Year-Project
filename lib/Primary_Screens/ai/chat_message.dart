// ─── Message Model ────────────────────────────────────────────────────────────
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage(this.text, this.sender, this.timestamp, {this.isLoading = false});
}
