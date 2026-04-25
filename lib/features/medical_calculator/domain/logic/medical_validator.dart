/// Universal medical input validator.
/// Returns null if valid, or an indonesian error message string if invalid.
class MedicalValidator {
  static String? weight(String? val) {
    if (val == null || val.trim().isEmpty) return 'Berat badan wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d <= 0) return 'Berat badan tidak boleh 0 atau negatif';
    if (d > 300) return 'Berat badan tidak logis (maks 300 kg)';
    return null;
  }

  static String? age(String? val) {
    if (val == null || val.trim().isEmpty) return 'Umur wajib diisi';
    final d = int.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d < 0) return 'Umur tidak boleh negatif';
    if (d > 120) return 'Umur tidak logis (maks 120 tahun)';
    return null;
  }

  static String? bloodPressure(String? val, String label) {
    if (val == null || val.trim().isEmpty) return '$label wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d < 10) return '$label terlalu rendah (min 10 mmHg)';
    if (d > 300) return '$label terlalu tinggi (maks 300 mmHg)';
    return null;
  }

  static String? height(String? val) {
    if (val == null || val.trim().isEmpty) return 'Tinggi badan wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d < 30) return 'Tinggi badan tidak logis (min 30 cm)';
    if (d > 250) return 'Tinggi badan tidak logis (maks 250 cm)';
    return null;
  }

  static String? dose(String? val) {
    if (val == null || val.trim().isEmpty) return 'Dosis wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d <= 0) return 'Dosis harus lebih dari 0';
    if (d > 10000) return 'Dosis terlalu besar, periksa kembali';
    return null;
  }

  static String? volume(String? val, String label) {
    if (val == null || val.trim().isEmpty) return '$label wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d <= 0) return '$label harus lebih dari 0';
    if (d > 10000) return '$label tidak logis (maks 10000 mL)';
    return null;
  }

  static String? creatinine(String? val) {
    if (val == null || val.trim().isEmpty) return 'Kreatinin wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d <= 0) return 'Kreatinin harus lebih dari 0';
    if (d > 30) return 'Nilai kreatinin tidak logis (maks 30 mg/dL)';
    return null;
  }

  static String? required(String? val, String label) {
    if (val == null || val.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? positiveNumber(String? val, String label, {double max = 99999}) {
    if (val == null || val.trim().isEmpty) return '$label wajib diisi';
    final d = double.tryParse(val);
    if (d == null) return 'Masukkan angka yang valid';
    if (d < 0) return '$label tidak boleh negatif';
    if (d > max) return '$label tidak logis (maks $max)';
    return null;
  }
}
