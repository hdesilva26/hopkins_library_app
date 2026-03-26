import 'book.dart';

class ClassModel {
  final String id;
  final String name;
  final String? subject;
  final List<Book> requiredBooks;

  ClassModel({
    required this.id,
    required this.name,
    this.subject,
    this.requiredBooks = const [],
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, List<Book> books) {
    return ClassModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      subject: map['subject'] as String?,
      requiredBooks: books,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'subject': subject};
  }
}
