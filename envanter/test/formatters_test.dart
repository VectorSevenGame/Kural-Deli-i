import 'package:envanter/domain/warranty.dart';
import 'package:envanter/util/formatters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('turkishUpper', () {
    test('noktali i buyuk harfte noktasini korur', () {
      expect(turkishUpper('künyesi'), 'KÜNYESİ');
      expect(turkishUpper('acil dikkat'), 'ACİL DİKKAT');
    });

    test('noktasiz i noktasiz kalir', () {
      expect(turkishUpper('ışık'), 'IŞIK');
      expect(turkishUpper('garantısı'), 'GARANTISI');
    });

    test('diger Turkce harfler bozulmaz', () {
      expect(turkishUpper('şçöüğ'), 'ŞÇÖÜĞ');
    });
  });

  group('formatPrice', () {
    test('tam sayida kurus gostermez', () {
      expect(formatPrice(845000), '₺8.450');
    });

    test('kurusluysa iki hane gosterir', () {
      expect(formatPrice(845075), contains('8.450,75'));
    });

    test('null icin tire', () {
      expect(formatPrice(null), '—');
    });
  });

  group('parsePrice', () {
    test('Turkce bicimi okur', () {
      expect(parsePrice('8.450,75'), 845075);
      expect(parsePrice('1200'), 120000);
    });

    test('gecersiz girdide null', () {
      expect(parsePrice('abc'), isNull);
      expect(parsePrice('-5'), isNull);
      expect(parsePrice(''), isNull);
    });
  });

  group('humanDuration', () {
    test('kisa sureler gun', () => expect(humanDuration(28), '28 Gün'));
    test('orta sureler ay', () => expect(humanDuration(240), '8 Ay'));
    test('uzun sureler yil', () => expect(humanDuration(730), '2 Yıl'));
    test('yil ve ay birlikte', () => expect(humanDuration(800), '2 Yıl 2 Ay'));
  });

  group('warrantyStatusLabel', () {
    test('her durumun kisa bir etiketi var', () {
      for (final status in WarrantyStatus.values) {
        expect(warrantyStatusLabel(status), isNotEmpty);
      }
    });
  });
}
