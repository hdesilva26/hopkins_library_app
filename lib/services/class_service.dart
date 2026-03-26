import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import '../models/book.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ClassModel>> getClasses() {
    return _firestore
        .collection('classes')
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
          final classes = <ClassModel>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final books = await _getClassBooks(doc.id);
            classes.add(ClassModel.fromMap({'id': doc.id, ...data}, books));
          }
          return classes;
        });
  }

  Future<List<ClassModel>> getClassesOnce() async {
    final snapshot = await _firestore
        .collection('classes')
        .orderBy('name')
        .get();

    final classes = <ClassModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final books = await _getClassBooks(doc.id);
      classes.add(ClassModel.fromMap({'id': doc.id, ...data}, books));
    }
    return classes;
  }

  Future<List<Book>> _getClassBooks(String classId) async {
    final booksSnapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('required_books')
        .orderBy('title')
        .get();

    return booksSnapshot.docs.map((doc) => Book.fromMap(doc.data())).toList();
  }

  Stream<ClassModel?> getClass(String classId) {
    return _firestore.collection('classes').doc(classId).snapshots().asyncMap((
      doc,
    ) async {
      if (!doc.exists) return null;
      final data = doc.data()!;
      final books = await _getClassBooks(classId);
      return ClassModel.fromMap({'id': doc.id, ...data}, books);
    });
  }

  Future<List<ClassModel>> searchClasses(String query) async {
    if (query.isEmpty) {
      return getClassesOnce();
    }

    final snapshot = await _firestore
        .collection('classes')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('name')
        .get();

    final classes = <ClassModel>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final books = await _getClassBooks(doc.id);
      classes.add(ClassModel.fromMap({'id': doc.id, ...data}, books));
    }
    return classes;
  }

  Future<void> createClass(String name, {String? subject}) async {
    await _firestore.collection('classes').add({
      'name': name,
      'subject': subject,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addRequiredBook(String classId, Book book) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('required_books')
        .doc(book.id.toString())
        .set(book.toMap());
  }

  Future<void> removeRequiredBook(String classId, int bookId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('required_books')
        .doc(bookId.toString())
        .delete();
  }
}
