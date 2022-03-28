class UniverseChatInfo {
  /// Number of online users.
  final int onlineUsers;

  /// Protocol version. (current version is 1)
  final int protocolVersion;

  UniverseChatInfo({
    required this.onlineUsers,
    required this.protocolVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      "onlineUsers": onlineUsers,
      "protocolVersion": protocolVersion,
    };
  }
}
