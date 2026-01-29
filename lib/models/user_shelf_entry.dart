/// User shelf data model for persisting reading status to Firestore
class UserShelfEntry {
  final String userId;
  final int bookId;
  final String shelfStatus;
  final DateTime updatedAt;

  const UserShelfEntry({
    required this.userId,
    required this.bookId,
    required this.shelfStatus,
    required this.updatedAt,
  });

  /// Create UserShelfEntry from Firestore document
  factory UserShelfEntry.fromMap(Map<String, dynamic> map) {
    return UserShelfEntry(
      userId: map['userId'] as String,
      bookId: map['bookId'] as int,
      shelfStatus: map['shelfStatus'] as String,
      updatedAt: (map['updatedAt'] as dynamic).toDate(),
    );
  }

  /// Convert UserShelfEntry to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bookId': bookId,
      'shelfStatus': shelfStatus,
      'updatedAt': updatedAt,
    };
  }

  /// Create copy with updated fields
  UserShelfEntry copyWith({String? shelfStatus, DateTime? updatedAt}) {
    return UserShelfEntry(
      userId: userId,
      bookId: bookId,
      shelfStatus: shelfStatus ?? this.shelfStatus,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserShelfEntry &&
        other.userId == userId &&
        other.bookId == bookId &&
        other.shelfStatus == shelfStatus;
  }

  @override
  int get hashCode => userId.hashCode ^ bookId.hashCode ^ shelfStatus.hashCode;

  @override
  String toString() =>
      'UserShelfEntry(userId: $userId, bookId: $bookId, shelfStatus: $shelfStatus)';
}
