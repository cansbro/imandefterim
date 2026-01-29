import json
import urllib.request
import time
import os

# Configuration
API_BASE_URL = "http://api.alquran.cloud/v1/surah"
EXISTING_DATA_PATH = "/Users/muratcan/imandefterim/imandefterim/imandefterim/Resources/quran_data.json"
OUTPUT_FILE = "quran_data_complete.json"

def load_existing_names():
    if not os.path.exists(EXISTING_DATA_PATH):
        print(f"Warning: Existing file not found at {EXISTING_DATA_PATH}. Using API names.")
        return {}
    
    try:
        with open(EXISTING_DATA_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
            names = {surah['id']: surah['name'] for surah in data}
            return names
    except Exception as e:
        print(f"Error reading existing data: {e}")
        return {}

def map_revelation_type(english_type):
    if english_type.lower() == "meccan":
        return "Mekke"
    elif english_type.lower() == "medinan":
        return "Medine"
    return english_type

def fetch_surah(surah_number):
    url = f"{API_BASE_URL}/{surah_number}/editions/quran-uthmani,tr.yazir,ar.alafasy"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
            return data['data']
    except Exception as e:
        print(f"Error fetching Surah {surah_number}: {e}")
        return None

def main():
    print("Loading existing Surah names...")
    existing_names = load_existing_names()
    
    complete_data = []
    
    print("Starting data fetch for 114 Surahs...")
    
    for i in range(1, 115):
        print(f"Fetching Surah {i}/114...")
        editions = fetch_surah(i)
        
        if not editions or len(editions) < 3:
            print("Failed to fetch all data. Aborting.")
            return

        # Find editions by identifier
        quran_data = next((e for e in editions if e['edition']['identifier'] == 'quran-uthmani'), None)
        translation_data = next((e for e in editions if e['edition']['identifier'] == 'tr.yazir'), None)
        audio_data = next((e for e in editions if e['edition']['identifier'] == 'ar.alafasy'), None)
        
        if not quran_data or not translation_data or not audio_data:
             print(f"Missing one of the editions for Surah {i}. Aborting.")
             return
        
        # Base Surah Object
        surah_obj = {
            "id": quran_data['number'],
            "name": existing_names.get(quran_data['number'], quran_data['englishName']), # Preserving existing Turkish name
            "arabicName": quran_data['name'],
            "meaning": "", # Requested to be empty
            "verseCount": quran_data['numberOfAyahs'],
            "revelationType": map_revelation_type(quran_data['revelationType']),
            "verses": []
        }
        
        # Process Verses
        for j in range(len(quran_data['ayahs'])):
            ayah_quran = quran_data['ayahs'][j]
            ayah_trans = translation_data['ayahs'][j]
            ayah_audio = audio_data['ayahs'][j]
            
            # Sanity check
            if ayah_quran['numberInSurah'] != ayah_trans['numberInSurah'] or ayah_quran['numberInSurah'] != ayah_audio['numberInSurah']:
                print(f"Mismatch in ayah numbering for Surah {i}!")
            
            verse_obj = {
                "id": ayah_quran['numberInSurah'], # Using numberInSurah as ID similar to previous structure
                "surahId": i,
                "number": ayah_quran['numberInSurah'],
                "arabicText": ayah_quran['text'],
                "turkishMeal": ayah_trans['text'],
                "audioUrl": ayah_audio['audio']
            }
            surah_obj['verses'].append(verse_obj)
            
        complete_data.append(surah_obj)
        time.sleep(0.5) # Be nice to the API
        
    print(f"Successfully processed {len(complete_data)} Surahs.")
    
    # Save to file
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(complete_data, f, ensure_ascii=False, indent=2)
        
    print(f"Data saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
