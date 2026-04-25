class MedicineSimple {
  final int id;
  final String namaGenerik;
  final String? namaDagang;
  final String? kode;
  final String? kodeNie;
  final String? golongan;
  final String? bentuk;
  final String? kelasTerapi;
  final String? kategoriKehamilan;

  MedicineSimple({
    required this.id,
    required this.namaGenerik,
    this.namaDagang,
    this.kode,
    this.kodeNie,
    this.golongan,
    this.bentuk,
    this.kelasTerapi,
    this.kategoriKehamilan,
  });

  factory MedicineSimple.fromMap(Map<String, dynamic> map) {
    return MedicineSimple(
      id: map['id'],
      namaGenerik: map['nama_generik'] ?? '',
      namaDagang: map['nama_dagang'],
      kode: map['kode'],
      kodeNie: map['kode_nie'],
      golongan: map['golongan'],
      bentuk: map['bentuk'],
      kelasTerapi: map['kelas_terapi'],
      kategoriKehamilan: map['kategori_kehamilan'],
    );
  }
}

class MedicineDetail {
  final int id;
  final String namaGenerik;
  final String? golongan;
  final String indikasi;
  final String? dosisDewasa;
  final String? dosisAnak;
  final String? satuan;
  final String? frekuensi;
  final String? efekSamping;
  final String? kontraindikasi;
  final String? interaksi;
  final String? overdosis;
  final String? peringatan;
  final String? edukasi;
  final String? kelasTerapi;
  final String? kategoriKehamilan;
  final String? penyesuaianGinjal;
  final String? clinicalPearls;
  final String? storage;

  MedicineDetail({
    required this.id,
    required this.namaGenerik,
    this.golongan,
    required this.indikasi,
    this.dosisDewasa,
    this.dosisAnak,
    this.satuan,
    this.frekuensi,
    this.efekSamping,
    this.kontraindikasi,
    this.interaksi,
    this.overdosis,
    this.peringatan,
    this.edukasi,
    this.kelasTerapi,
    this.kategoriKehamilan,
    this.penyesuaianGinjal,
    this.clinicalPearls,
    this.storage,
  });

  factory MedicineDetail.fromMap(Map<String, dynamic> map) {
    return MedicineDetail(
      id: map['id'],
      namaGenerik: map['nama_generik'] ?? '',
      golongan: map['golongan'],
      indikasi: map['indikasi'] ?? '',
      dosisDewasa: map['dosis_dewasa'],
      dosisAnak: map['dosis_anak'],
      satuan: map['satuan'],
      frekuensi: map['frekuensi'],
      efekSamping: map['efek_samping'],
      kontraindikasi: map['kontraindikasi'],
      interaksi: map['interaksi'],
      overdosis: map['overdosis'],
      peringatan: map['peringatan'],
      edukasi: map['edukasi'],
      kelasTerapi: map['kelas_terapi'],
      kategoriKehamilan: map['kategori_kehamilan'],
      penyesuaianGinjal: map['penyesuaian_ginjal'],
      clinicalPearls: map['clinical_pearls'],
      storage: map['storage'],
    );
  }
}
