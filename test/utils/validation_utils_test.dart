import 'package:flutter_test/flutter_test.dart';
import 'package:wonwonw2/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    group('Email Validation', () {
      test('should validate correct email addresses', () {
        expect(ValidationUtils.isValidEmail('test@example.com'), true);
        expect(ValidationUtils.isValidEmail('user.name@domain.co.uk'), true);
        expect(ValidationUtils.isValidEmail('test+tag@example.org'), true);
      });

      test('should reject invalid email addresses', () {
        expect(ValidationUtils.isValidEmail(''), false);
        expect(ValidationUtils.isValidEmail('invalid-email'), false);
        expect(ValidationUtils.isValidEmail('@example.com'), false);
        expect(ValidationUtils.isValidEmail('test@'), false);
        expect(ValidationUtils.isValidEmail('test..test@example.com'), false);
      });
    });

    group('Phone Validation', () {
      test('should validate correct phone numbers', () {
        expect(ValidationUtils.isValidPhone('+1234567890'), true);
        expect(ValidationUtils.isValidPhone('1234567890'), true);
        expect(ValidationUtils.isValidPhone('+66812345678'), true);
      });

      test('should reject invalid phone numbers', () {
        expect(ValidationUtils.isValidPhone(''), false);
        expect(ValidationUtils.isValidPhone('123'), false);
        expect(ValidationUtils.isValidPhone('abc123'), false);
        expect(ValidationUtils.isValidPhone('+123456789012345'), false);
      });
    });

    group('Password Validation', () {
      test('should validate strong passwords', () {
        expect(ValidationUtils.isValidPassword('Password123'), true);
        expect(ValidationUtils.isValidPassword('MyStr0ng!Pass'), true);
        expect(ValidationUtils.isValidPassword('Test1234'), true);
      });

      test('should reject weak passwords', () {
        expect(ValidationUtils.isValidPassword(''), false);
        expect(ValidationUtils.isValidPassword('1234567'), false); // too short
        expect(ValidationUtils.isValidPassword('password'), false); // no uppercase, no number
        expect(ValidationUtils.isValidPassword('PASSWORD'), false); // no lowercase, no number
        expect(ValidationUtils.isValidPassword('Password'), false); // no number
      });
    });

    group('Shop Validation', () {
      test('should validate shop names', () {
        expect(ValidationUtils.isValidShopName('My Shop'), true);
        expect(ValidationUtils.isValidShopName('A'), false); // too short
        expect(ValidationUtils.isValidShopName('A' * 101), false); // too long
      });

      test('should validate shop descriptions', () {
        expect(ValidationUtils.isValidShopDescription('A good shop'), true);
        expect(ValidationUtils.isValidShopDescription('Bad'), false); // too short
        expect(ValidationUtils.isValidShopDescription('A' * 1001), false); // too long
      });

      test('should validate shop addresses', () {
        expect(ValidationUtils.isValidShopAddress('123 Main Street, City'), true);
        expect(ValidationUtils.isValidShopAddress('Short'), false); // too short
        expect(ValidationUtils.isValidShopAddress('A' * 201), false); // too long
      });
    });

    group('Rating Validation', () {
      test('should validate ratings', () {
        expect(ValidationUtils.isValidRating(1.0), true);
        expect(ValidationUtils.isValidRating(5.0), true);
        expect(ValidationUtils.isValidRating(3.5), true);
        expect(ValidationUtils.isValidRating(0.5), false); // too low
        expect(ValidationUtils.isValidRating(5.5), false); // too high
      });
    });

    group('Coordinate Validation', () {
      test('should validate coordinates', () {
        expect(ValidationUtils.isValidLatitude(0.0), true);
        expect(ValidationUtils.isValidLatitude(90.0), true);
        expect(ValidationUtils.isValidLatitude(-90.0), true);
        expect(ValidationUtils.isValidLatitude(91.0), false);
        expect(ValidationUtils.isValidLatitude(-91.0), false);

        expect(ValidationUtils.isValidLongitude(0.0), true);
        expect(ValidationUtils.isValidLongitude(180.0), true);
        expect(ValidationUtils.isValidLongitude(-180.0), true);
        expect(ValidationUtils.isValidLongitude(181.0), false);
        expect(ValidationUtils.isValidLongitude(-181.0), false);
      });
    });

    group('String Sanitization', () {
      test('should sanitize strings', () {
        expect(ValidationUtils.sanitizeString('  hello  world  '), 'hello world');
        expect(ValidationUtils.sanitizeString('hello\n\nworld'), 'hello world');
        expect(ValidationUtils.sanitizeString('hello\t\tworld'), 'hello world');
      });

      test('should sanitize HTML', () {
        expect(ValidationUtils.sanitizeHtml('<p>Hello</p>'), 'Hello');
        expect(ValidationUtils.sanitizeHtml('<script>alert("xss")</script>Hello'), 'Hello');
        expect(ValidationUtils.sanitizeHtml('<b>Bold</b> text'), 'Bold text');
      });
    });

    group('Pagination Validation', () {
      test('should validate pagination parameters', () {
        expect(ValidationUtils.isValidPagination(0, 10), true);
        expect(ValidationUtils.isValidPagination(1, 20), true);
        expect(ValidationUtils.isValidPagination(-1, 10), false);
        expect(ValidationUtils.isValidPagination(0, 0), false);
        expect(ValidationUtils.isValidPagination(0, 101), false);
      });

      test('should normalize pagination parameters', () {
        final result1 = ValidationUtils.normalizePagination(-1, 0);
        expect(result1['page'], 0);
        expect(result1['limit'], 20);

        final result2 = ValidationUtils.normalizePagination(5, 150);
        expect(result2['page'], 5);
        expect(result2['limit'], 100);
      });
    });
  });
}
