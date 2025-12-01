# ♟️ Elixir CLI Chess

Selamat datang di **Elixir CLI Chess**, sebuah permainan catur klasik yang dimainkan langsung melalui terminal komputer.

Proyek ini dikembangkan sebagai tugas akhir untuk mata kuliah **Pemrograman Fungsional** yang menggabungkan strategi kompleks catur dengan keindahan kode yang bersih dan matematis.

## Projek Apa Ini?

Projek ini merealisasikan permainan catur yang dapat dimainkan dari terminal komputer. Kami membangun seluruh logic dan aturan permainan catur dari nol.

Tujuan proyek ini adalah membuktikan bahwa kita bisa membuat simulasi permainan yang kompleks menggunakan pendekatan pemrograman yang sangat berbeda dari biasanya, yaitu dengan pemrograman fungsional menggunakan **Elixir**.

Catur ini dapat dimainkan dengan dua opsi, melawan orang lain, ataupun melawan bot yang sudah dilatih agar mengambil langkah yang baik.

## Pendekatan & Teknologi

Proyek ini dibangun menggunakan bahasa pemrograman **Elixir**. Mengapa ini istimewa? Karena kami menggunakan paradigma **Functional Programming**.

### Apa Bedanya dengan Pendekatan Biasa?

Dalam pemrograman biasa (atau dikenal juga dengan pemrograman imperatif), ibaratnya kita menulis di papan tulis. Jika ada perubahan (misal bidak bergerak), kita menghapus posisi lama dan menggambarnya di tempat baru. Papan tulisnya "berubah" dan coretan lama hilang selamanya.

Dalam Functional Programming, kami mengibaratkannya dengan pengambilan foto.

1.  Saat bidak bergerak, kami tidak mengubah papan yang lama.
2.  Kami menciptakan papan baru yang merupakan hasil dari gerakan tersebut.
3.  Papan yang lama tetap ada di memori.

**Keuntungan pendekatan ini:**

- **Time Travel:** Karena papan lama tidak pernah "dihapus", fitur seperti Undo atau Replay menjadi sangat mudah dibuat dan 100% akurat.
- **Minimalisir Error:** Karena data tidak berubah-ubah secara diam-diam, program menjadi lebih stabil dan jarang _crash_ akibat kebingungan status data.

## Fitur Utama

Meskipun berbasis teks, game ini memiliki fitur lengkap layaknya aplikasi catur modern:

### Kecerdasan Buatan (AI)

- **Player vs Bot:** Pemain dapat melawan bot yang menggunakan algoritma _Greedy_.
- **Evaluasi Real-time:** Bot bisa menilai apakah posisi Anda sedang unggul atau kalah (ditampilkan dengan skor angka, misal: `+30` berarti Putih unggul).

### Aturan Catur Lengkap

Semua aturan validasi gerakan diterapkan:

- Gerakan dasar semua bidak (Pawn, Horse, Rook, Bishop, Queen, King).
- **Check & Checkmate:** Sistem mendeteksi jika Raja terancam atau permainan berakhir.
- **Gerakan Spesial:** Mendukung _Castling_ (Rokade), _Pawn Promotion_ (Promosi Pion), dan _En Passant_.

### Kontrol Permainan

Berkat pendekatan _Functional Programming_, kami memiliki fitur manipulasi waktu:

- **Undo:** Salah langkah? Batalkan gerakan terakhir tanpa batas.
- **Save & Load:** Simpan permainan ke dalam file dan lanjutkan kapan saja.
- **Replay:** Tonton ulang seluruh jalannya pertandingan dari awal hingga akhir secara otomatis.

### Fitur Tambahan

- **Timer Catur:** Waktu berjalan mundur untuk setiap pemain (1, 3, atau 5 menit).
- **Visualisasi Terminal:** Papan catur ditampilkan rapi menggunakan simbol Unicode (♜, ♞, ♝) dan koordinat.

---

## Cara Menjalankan

Pastikan **Elixir** sudah terinstal di komputer Anda.

1.  Buka terminal di folder proyek.
2.  Jalankan perintah berikut:
    ```bash
    mix run -e "Chess.run()"
    ```
3.  Ikuti instruksi di layar untuk memilih waktu dan mulai bermain!
