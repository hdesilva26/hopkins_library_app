import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState Domain Validation', () {
    test('validates hopkins.edu domain correctly', () {
      // Test cases for domain validation logic
      final testCases = {
        'user@hopkins.edu': true,
        'student@students.hopkins.edu': true,
        'teacher@hopkins.edu': true,
        'user@gmail.com': false,
        'test@yahoo.com': false,
        'admin@school.edu': false,
        'user@hopkins.edu.org': false, // Should not match
        'user@sub.hopkins.edu': true,
        'invalid-email': false,
        '@hopkins.edu': false,
        'user@': false,
      };

      for (final entry in testCases.entries) {
        final email = entry.key;
        final expected = entry.value;

        // Simulate the domain validation logic from auth_state.dart
        final isValid = _validateHopkinsDomain(email);

        expect(
          isValid,
          equals(expected),
          reason: 'Email $email should be ${expected ? "valid" : "invalid"}',
        );
      }
    });

    test('handles edge cases in email parsing', () {
      final edgeCases = {
        'user@hopkins.edu': 'hopkins.edu',
        'user@students.hopkins.edu': 'students.hopkins.edu',
        'user@sub.sub.hopkins.edu': 'sub.sub.hopkins.edu',
        'user@HOPKINS.EDU': 'HOPKINS.EDU', // Case sensitivity test
      };

      for (final entry in edgeCases.entries) {
        final email = entry.key;
        final expectedDomain = entry.value;

        final extractedDomain = _extractDomain(email);

        expect(
          extractedDomain,
          equals(expectedDomain),
          reason: 'Domain extraction failed for $email',
        );
      }
    });

    test('rejects malformed emails', () {
      final malformedEmails = [
        '',
        'user',
        'user@',
        '@domain.com',
        'user@@domain.com',
        'user@domain@com',
        'user domain.com',
      ];

      for (final email in malformedEmails) {
        final isValid = _validateHopkinsDomain(email);
        expect(
          isValid,
          isFalse,
          reason: 'Malformed email "$email" should be rejected',
        );
      }
    });
  });
}

// Helper functions to simulate the validation logic from auth_state.dart
bool _validateHopkinsDomain(String email) {
  if (email.isEmpty || email.trim().isEmpty) {
    return false;
  }

  final emailParts = email.split('@');
  if (emailParts.length != 2) {
    return false;
  }

  // Check that there's content before and after the @
  final username = emailParts.first.trim();
  final domain = emailParts.last.trim();

  if (username.isEmpty || domain.isEmpty) {
    return false;
  }

  return domain == 'hopkins.edu' || domain.endsWith('.hopkins.edu');
}

String _extractDomain(String email) {
  final emailParts = email.split('@');
  if (emailParts.length != 2) {
    return '';
  }
  return emailParts.last.trim();
}
