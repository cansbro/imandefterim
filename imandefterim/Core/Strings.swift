import SwiftUI

// MARK: - Turkish Strings (Sadece Türkçe)
enum Strings {

    // MARK: - App
    enum App {
        static let name = "İman Defterim"
        static let nameASCII = "Iman Defterim"
        static let tagline = "Kalbinin Defteri"
    }

    // MARK: - Tab Bar
    enum Tab {
        static let notes = "Notlar"
        static let today = "Bugün"
        static let quran = "Kur'an"
        static let settings = "Ayarlar"
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let welcome = "İman Defterim'e Hoş Geldin"
        static let page1Title = "Kaydet ve Özetle"
        static let page1Subtitle = "Vaazları kaydet, yapay zeka ile transkript ve özet oluştur"

        static let page2Title = "Namaz Vakitleri"
        static let page2Subtitle = "Şehrini seç, namaz vakitlerini takip et"

        static let page3Title = "Kur'an Notları"
        static let page3Subtitle = "Ayetleri notlarına ekle, tefekkür et"

        static let getStarted = "Başla"
        static let next = "İleri"
        static let skip = "Atla"
        static let selectCity = "Şehir Seç"
    }

    // MARK: - Notes
    enum Notes {
        static let title = "Notlar"
        static let all = "Tümü"
        static let folders = "Klasörler"
        static let search = "Ara..."
        static let newFolder = "Yeni Klasör"
        static let folderName = "Klasör Adı"
        static let create = "Oluştur"
        static let emptyTitle = "Henüz Not Yok"
        static let emptyMessage = "Kayıt yaparak veya ayet ekleyerek başlayın"
        static let emptyFolderTitle = "Klasör Boş"
        static let createFolder = "Klasör Oluştur"

        // Tags
        static let tagSummary = "Özet"
        static let tagTranscript = "Transkript"
        static let tagDua = "Dua"
        static let tagPersonal = "Kişisel Not"
    }

    // MARK: - Recording
    enum Recording {
        static let title = "Kayıt"
        static let startRecording = "Ses Kaydı Başlat"
        static let textNote = "Metin Notu"
        static let tapToRecord = "Kayda başlamak için dokun"
        static let recording = "Kaydediliyor..."
        static let paused = "Duraklatıldı"
        static let save = "Kaydet"
        static let saveRecording = "Kaydı Kaydet"
        static let discard = "Sil"
        static let pause = "Duraklat"
        static let resume = "Devam"
        static let titlePlaceholder = "Kayıt Başlığı"
        static let speakerPlaceholder = "Konuşmacı (opsiyonel)"
        static let processing = "İşleniyor..."

        // Detail Tabs
        static let summary = "Özet"
        static let transcript = "Transkript"
        static let duas = "Dualar"
        static let notes = "Notlar"

        // Share
        static let share = "Paylaş"
        static let addNote = "Not Ekle"
    }

    // MARK: - Today
    enum Today {
        static let title = "Bugün"
        static let todaysGuide = "Bugünün Rehberi"
        static let guideTitle = "İman Defterim ile Bugün"
        static let begin = "Başla"
        static let nextPrayer = "Sıradaki Namaz"
        static let dailyVerse = "Günün Ayeti"
        static let prayerTimes = "Namaz Vakitleri"
        static let remainingTime = "Kalan"
    }

    // MARK: - Prayer Times
    enum Prayer {
        static let title = "Namaz Vakitleri"
        static let imsak = "İmsak"
        static let gunes = "Güneş"
        static let ogle = "Öğle"
        static let ikindi = "İkindi"
        static let aksam = "Akşam"
        static let yatsi = "Yatsı"
        static let next = "Sıradaki"
        static let refresh = "Yenile"
    }

    // MARK: - Quran
    enum Quran {
        static let title = "Kur'an-ı Kerim"
        static let surahs = "Sureler"
        static let verses = "Ayet"
        static let addToNotes = "Notlara Ekle"
        static let share = "Paylaş"
        static let bookmark = "İşaretle"
        static let showArabic = "Arapça Göster"
        static let hideArabic = "Arapçayı Gizle"
        static let fontSize = "Yazı Boyutu"
        static let meal = "Meal"
    }

    // MARK: - Settings
    enum Settings {
        static let title = "Ayarlar"
        static let city = "Şehir (İl)"
        static let selectCity = "Şehir Seç"
        static let prayerSettings = "Namaz Ayarları"
        static let notifications = "Bildirimler"
        static let about = "Hakkında"
        static let feedback = "Geri Bildirim"
        static let rateApp = "Uygulamayı Değerlendir"
        static let version = "Sürüm"
        static let privacyPolicy = "Gizlilik Politikası"
        static let termsOfUse = "Kullanım Koşulları"
    }

    // MARK: - Premium
    enum Premium {
        static let title = "Premium'a Geç"
        static let subtitle = "İman Defterim Premium ile sınırsız kayıt"
        static let upgrade = "Yükselt"
        static let features = "Sınırsız kayıt • Gelişmiş AI • Reklamsız"
        static let viewPlans = "Planları Gör"
        static let premiumOpen = "Premium'u Aç"
        static let later = "Daha Sonra"
        static let restorePurchases = "Satın alımları geri yükle"
        static let termsAndPrivacy = "Koşullar ve Gizlilik"
        static let cancelAnytime = "İstediğin zaman iptal edebilirsin."
        static let yearlyBenefit = "Yıllık planla daha az öde, tüm yıl kesintisiz kullan."

        // Limit messages
        static let limitReached = "Limitine Ulaştın"
        static let monthlyLimitMessage =
            "Bu ayki ücretsiz kullanım hakkın doldu. Premium ile sınırsız kayıt yapabilir, daha fazla transkript ve özet çıkarabilirsin."
        static let recordingLimitMessage = "Bu ayki ücretsiz kayıt hakkın doldu."
        static let transcriptLimitMessage = "Bu ayki ücretsiz transkript kotan doldu."

        // Quota
        static let monthlyUsage = "Aylık Kullanım"
        static let recordingQuota = "Kayıt Hakkı"
        static let transcriptQuota = "Transkript & Özet"
        static let aiProcessing = "AI İşleme"
        static let unlimited = "Sınırsız"
        static let remaining = "kaldı"

        // Plans
        static let mostPopular = "En Popüler"
        static let mostPowerful = "En Güçlü"
        static let mostAdvantaged = "En Avantajlı"
        static let mostPreferred = "En Çok Tercih Edilen"
        static let savings = "Tasarruf"

        // CTAs
        static let selectStarter = "Starter'ı Seç"
        static let selectPro = "Pro'ya Geç"
        static let continueBtn = "Devam Et"
    }

    // MARK: - Common
    enum Common {
        static let cancel = "İptal"
        static let save = "Kaydet"
        static let delete = "Sil"
        static let edit = "Düzenle"
        static let done = "Tamam"
        static let ok = "Tamam"
        static let loading = "Yükleniyor..."
        static let error = "Hata"
        static let success = "Başarılı"
        static let retry = "Tekrar Dene"
    }
}
