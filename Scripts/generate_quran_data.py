#!/usr/bin/env python3
"""
Quran Data Generator for IslamicNotes App
Fetches Arabic text and Turkish translation (Elmalılı Hamdi Yazır) from fawazahmed0/quran-api
and generates Swift code for QuranData.swift
"""

import json
import urllib.request
import ssl
import sys

# API Endpoints
TURKISH_URL = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/tur-elmalilihamdiya-la.json"
ARABIC_URL = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-qurandoori.json"
INFO_URL = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/info.json"

# Create SSL context that doesn't verify certificates (for macOS compatibility)
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Surah names and meanings in Turkish
SURAH_TURKISH = {
    1: ("Fatiha", "Açılış"),
    2: ("Bakara", "İnek"),
    3: ("Âl-i İmran", "İmran Ailesi"),
    4: ("Nisâ", "Kadınlar"),
    5: ("Mâide", "Sofra"),
    6: ("En'âm", "Hayvanlar"),
    7: ("A'râf", "Yükseklikler"),
    8: ("Enfâl", "Ganimetler"),
    9: ("Tevbe", "Tövbe"),
    10: ("Yûnus", "Yunus"),
    11: ("Hûd", "Hud"),
    12: ("Yûsuf", "Yusuf"),
    13: ("Ra'd", "Gök Gürültüsü"),
    14: ("İbrâhîm", "İbrahim"),
    15: ("Hicr", "Hicr"),
    16: ("Nahl", "Arı"),
    17: ("İsrâ", "Gece Yolculuğu"),
    18: ("Kehf", "Mağara"),
    19: ("Meryem", "Meryem"),
    20: ("Tâhâ", "Tâhâ"),
    21: ("Enbiyâ", "Peygamberler"),
    22: ("Hac", "Hac"),
    23: ("Mü'minûn", "Müminler"),
    24: ("Nûr", "Işık"),
    25: ("Furkân", "Ayırıcı"),
    26: ("Şuarâ", "Şairler"),
    27: ("Neml", "Karınca"),
    28: ("Kasas", "Kıssalar"),
    29: ("Ankebût", "Örümcek"),
    30: ("Rûm", "Rumlar"),
    31: ("Lokmân", "Lokman"),
    32: ("Secde", "Secde"),
    33: ("Ahzâb", "Topluluklar"),
    34: ("Sebe'", "Sebe"),
    35: ("Fâtır", "Yaratan"),
    36: ("Yâsîn", "Ya-Sin"),
    37: ("Sâffât", "Saf Tutanlar"),
    38: ("Sâd", "Sad"),
    39: ("Zümer", "Gruplar"),
    40: ("Mü'min", "Mümin"),
    41: ("Fussilet", "Ayrıntılı"),
    42: ("Şûrâ", "Danışma"),
    43: ("Zuhruf", "Altın Süsler"),
    44: ("Duhân", "Duman"),
    45: ("Câsiye", "Diz Çöken"),
    46: ("Ahkâf", "Kum Tepeleri"),
    47: ("Muhammed", "Muhammed"),
    48: ("Fetih", "Fetih"),
    49: ("Hucurât", "Odalar"),
    50: ("Kâf", "Kaf"),
    51: ("Zâriyât", "Savuranlar"),
    52: ("Tûr", "Dağ"),
    53: ("Necm", "Yıldız"),
    54: ("Kamer", "Ay"),
    55: ("Rahmân", "Rahman"),
    56: ("Vâkıa", "Kıyamet"),
    57: ("Hadîd", "Demir"),
    58: ("Mücâdele", "Tartışma"),
    59: ("Haşr", "Toplanma"),
    60: ("Mümtehine", "Sınanan Kadın"),
    61: ("Saff", "Saf"),
    62: ("Cuma", "Cuma"),
    63: ("Münâfikûn", "Münafıklar"),
    64: ("Teğâbün", "Aldanma"),
    65: ("Talâk", "Boşanma"),
    66: ("Tahrîm", "Yasaklama"),
    67: ("Mülk", "Mülk"),
    68: ("Kalem", "Kalem"),
    69: ("Hâkka", "Gerçekleşen"),
    70: ("Meâric", "Yükseliş Yolları"),
    71: ("Nûh", "Nuh"),
    72: ("Cin", "Cinler"),
    73: ("Müzzemmil", "Örtünen"),
    74: ("Müddessir", "Bürünen"),
    75: ("Kıyâme", "Kıyamet"),
    76: ("İnsân", "İnsan"),
    77: ("Mürselât", "Gönderilenler"),
    78: ("Nebe'", "Haber"),
    79: ("Nâziât", "Çekip Çıkaranlar"),
    80: ("Abese", "Yüzünü Ekşitti"),
    81: ("Tekvîr", "Dürülme"),
    82: ("İnfitâr", "Parçalanma"),
    83: ("Mutaffifîn", "Eksik Ölçenler"),
    84: ("İnşikâk", "Yarılma"),
    85: ("Bürûc", "Burçlar"),
    86: ("Târık", "Gece Gelen"),
    87: ("A'lâ", "En Yüce"),
    88: ("Ğâşiye", "Kaplayan"),
    89: ("Fecr", "Şafak"),
    90: ("Beled", "Şehir"),
    91: ("Şems", "Güneş"),
    92: ("Leyl", "Gece"),
    93: ("Duhâ", "Kuşluk"),
    94: ("İnşirâh", "Ferahlama"),
    95: ("Tîn", "İncir"),
    96: ("Alak", "Asılan"),
    97: ("Kadr", "Kadir Gecesi"),
    98: ("Beyyine", "Açık Delil"),
    99: ("Zilzâl", "Deprem"),
    100: ("Âdiyât", "Koşanlar"),
    101: ("Kâria", "Çarpan"),
    102: ("Tekâsür", "Çokluk Yarışı"),
    103: ("Asr", "Asır"),
    104: ("Hümeze", "Dedikoducu"),
    105: ("Fîl", "Fil"),
    106: ("Kureyş", "Kureyş"),
    107: ("Mâûn", "Yardım"),
    108: ("Kevser", "Bolluk"),
    109: ("Kâfirûn", "Kafirler"),
    110: ("Nasr", "Zafer"),
    111: ("Tebbet", "Alev"),
    112: ("İhlâs", "Samimiyet"),
    113: ("Felak", "Sabah Aydınlığı"),
    114: ("Nâs", "İnsanlar"),
}

def fetch_json(url):
    """Fetch JSON from URL"""
    print(f"Fetching: {url}")
    with urllib.request.urlopen(url, context=ssl_context) as response:
        return json.loads(response.read().decode('utf-8'))

def escape_swift_string(s):
    """Escape special characters for Swift string literals"""
    if s is None:
        return ""
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

def main():
    print("Fetching Quran data from API...")
    
    # Fetch all data
    turkish_data = fetch_json(TURKISH_URL)
    arabic_data = fetch_json(ARABIC_URL)
    info_data = fetch_json(INFO_URL)
    
    # Index verses by chapter
    turkish_verses = {}
    for verse in turkish_data['quran']:
        chapter = verse['chapter']
        if chapter not in turkish_verses:
            turkish_verses[chapter] = []
        turkish_verses[chapter].append(verse)
    
    arabic_verses = {}
    for verse in arabic_data['quran']:
        chapter = verse['chapter']
        if chapter not in arabic_verses:
            arabic_verses[chapter] = []
        arabic_verses[chapter].append(verse)
    
    # Get surah info from info.json
    surah_info = {}
    for chapter_info in info_data['chapters']:
        chapter_num = chapter_info['chapter']
        surah_info[chapter_num] = {
            'arabic_name': chapter_info['arabicname'],
            'revelation': 'Mekki' if chapter_info['revelation'] == 'Mecca' else 'Medeni',
            'verse_count': len(chapter_info['verses'])
        }
    
    # Generate Swift code
    swift_code = '''import Foundation

// MARK: - Surah Model
struct Surah: Identifiable {
    let id: Int
    let name: String
    let arabicName: String
    let meaning: String
    let verseCount: Int
    let revelationType: String  // Mekki / Medeni
    var verses: [Verse]

    var displayName: String {
        "\\(id). \\(name)"
    }
}

// MARK: - Verse (Ayet) Model
struct Verse: Identifiable {
    let id: Int
    let surahId: Int
    let number: Int
    let arabicText: String?
    let turkishMeal: String

    var reference: String {
        "\\(surahId):\\(number)"
    }
}

// MARK: - All Quran Data (114 Surahs)
struct QuranData {
    static let allSurahs: [Surah] = [
'''
    
    # Generate each surah
    for surah_num in range(1, 115):
        info = surah_info[surah_num]
        name, meaning = SURAH_TURKISH.get(surah_num, (f"Surah {surah_num}", ""))
        
        arabic_name = escape_swift_string(info['arabic_name'])
        revelation = info['revelation']
        verse_count = info['verse_count']
        
        swift_code += f'''        Surah(
            id: {surah_num},
            name: "{name}",
            arabicName: "{arabic_name}",
            meaning: "{meaning}",
            verseCount: {verse_count},
            revelationType: "{revelation}",
            verses: [
'''
        
        # Add verses
        tr_verses = turkish_verses.get(surah_num, [])
        ar_verses = arabic_verses.get(surah_num, [])
        
        for i, tr_verse in enumerate(tr_verses):
            verse_num = tr_verse['verse']
            tr_text = escape_swift_string(tr_verse['text'])
            
            # Get corresponding Arabic text
            ar_text = ""
            for ar_v in ar_verses:
                if ar_v['verse'] == verse_num:
                    ar_text = escape_swift_string(ar_v['text'])
                    break
            
            swift_code += f'''                Verse(id: {i+1}, surahId: {surah_num}, number: {verse_num}, arabicText: "{ar_text}", turkishMeal: "{tr_text}"),
'''
        
        swift_code += '''            ]
        ),
'''
    
    swift_code += '''    ]

    static func getSurah(by id: Int) -> Surah? {
        allSurahs.first { $0.id == id }
    }
    
    static func searchSurahs(_ query: String) -> [Surah] {
        if query.isEmpty { return allSurahs }
        return allSurahs.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.meaning.localizedCaseInsensitiveContains(query) ||
            $0.arabicName.contains(query)
        }
    }
}
'''
    
    # Write output
    output_path = "../IslamicNotes/Models/QuranData.swift"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(swift_code)
    
    print(f"\n✅ Generated {output_path}")
    print(f"   - 114 Surahs")
    print(f"   - {sum(info['verse_count'] for info in surah_info.values())} Verses")
    print(f"   - Arabic text + Elmalılı Hamdi Yazır Turkish translation")

if __name__ == "__main__":
    main()
