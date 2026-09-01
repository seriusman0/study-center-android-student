import 'dart:convert';
import 'features/journal/models/journal_model.dart';
void main() {
  final jsonString = '''{"date":"2026-09-01","week":{"tahun":2026,"bulan":9,"minggu":1,"key":"2026-09-1"},"bible":{"day_no":219,"pl_porsi":"Mzm 11-17","pb_porsi":"Rom 13:1-14","pl_checked":false,"pb_checked":false},"verse_ref":null,"verse_checked":false,"show_verse":true,"foto_belajar_url":null,"life_items":[{"id":2,"kategori":"kerohanian","label":"Baca Alkitab","response_type":"check","checked":false},{"id":3,"kategori":"kerohanian","label":"Hafal Ayat","response_type":"check","checked":false},{"id":1,"kategori":"kerohanian","label":"Mengawali hari dengan berdoa","response_type":"check","checked":false},{"id":4,"kategori":"pendidikan","label":"Hadir di kelas SC","response_type":"check","checked":false},{"id":6,"kategori":"pendidikan","label":"Hadir Pembinaan hari Minggu","response_type":"check","checked":false},{"id":5,"kategori":"pendidikan","label":"Hadir Pembinaan hari Sabtu","response_type":"check","checked":false},{"id":8,"kategori":"karakter","label":"Menyapa orangtua/guru/kakak","response_type":"check","checked":false},{"id":7,"kategori":"karakter","label":"Merapikan tempat tidur","response_type":"check","checked":false}]}''';
  try {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final snap = JournalSnapshot.fromJson(map);
    print('Parsed successfully!');
    print('Date: \');
    print('Life items count: \');
    print('Categories: \');
  } catch (e, stack) {
    print('Error: \');
    print(stack);
  }
}
