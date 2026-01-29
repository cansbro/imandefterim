import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as fs from "fs";
// import OpenAI from "openai"; // Removed
import { GoogleGenerativeAI } from "@google/generative-ai";

admin.initializeApp();

const db = admin.firestore();

// ============================================
// AI Configurations
// ============================================

// OpenAI (Removed - using Gemini for everything)
// const openai = ...

// Gemini (For Chat)
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "dummy_key");
const geminiModel = genAI.getGenerativeModel({ model: "gemini-3-pro-preview" });

// ============================================
// Audio Processing
// ============================================

/**
 * Storage trigger: Yeni audio yüklendiğinde işleme başlat
 */
export const onAudioUploaded = functions.runWith({
    timeoutSeconds: 300,
    memory: "1GB",
}).storage
    .object()
    .onFinalize(async (object) => {
        const filePath = object.name;
        console.log("📂 Storage Triggered. File Path:", filePath);

        if (!filePath || !filePath.includes("/audio/")) {
            console.log("⚠️ Not an audio file path, skipping.");
            return null;
        }

        // Path: users/{uid}/audio/{noteId}.m4a
        const decodedPath = decodeURIComponent(filePath);
        console.log("📂 Decoded Path:", decodedPath);

        const pathParts = decodedPath.split("/");
        const fileName = pathParts[pathParts.length - 1]; // "noteId.m4a"
        const noteId = fileName.split(".")[0];
        const bucketName = object.bucket;

        // UID Extraction Attempt
        const uidIndex = pathParts.indexOf("users") + 1;
        const uid = (uidIndex > 0 && uidIndex < pathParts.length) ? pathParts[uidIndex] : "unknown";

        console.log(`🔍 Processing audio for Note ID: [${noteId}], User ID: [${uid}]`);

        if (!noteId || noteId.length < 5) {
            console.error("❌ Invalid Note ID extracted:", noteId);
            return null;
        }

        await processNoteAudio(noteId, bucketName, filePath);
        return null;
    });

/**
 * Manuel Retry Function
 */
export const retryProcessNote = functions.runWith({
    timeoutSeconds: 300,
    memory: "1GB",
}).https.onCall(async (data, context) => {
    // Auth Check
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısınız.");
    }

    const { noteId } = data;
    if (!noteId) {
        throw new functions.https.HttpsError("invalid-argument", "Note ID gerekli.");
    }

    const uid = context.auth.uid;
    console.log(`🔄 Retry requested for Note ID: [${noteId}] by User: [${uid}]`);

    try {
        const noteRef = db.collection("notes").doc(noteId);
        const noteDoc = await noteRef.get();

        if (!noteDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Not bulunamadı.");
        }

        const noteData = noteDoc.data();
        if (noteData?.uid !== uid) {
            throw new functions.https.HttpsError("permission-denied", "Bu not size ait değil.");
        }

        const audioStoragePath = noteData?.audioStoragePath;
        if (!audioStoragePath) {
            throw new functions.https.HttpsError("failed-precondition", "Ses dosyası yolu bulunamadı.");
        }

        const bucketName = admin.storage().bucket().name;

        await processNoteAudio(noteId, bucketName, audioStoragePath);

        return { success: true, message: "İşlem tekrar başlatıldı." };

    } catch (error: any) {
        console.error("Retry Error:", error);
        throw new functions.https.HttpsError("internal", error.message || "Tekrar deneme başarısız.");
    }
});

/**
 * Shared Audio Processing Logic (Pure Gemini Implementation)
 */
async function processNoteAudio(noteId: string, bucketName: string, filePath: string) {
    const noteRef = db.collection("notes").doc(noteId);

    const noteDoc = await noteRef.get();
    if (!noteDoc.exists) {
        console.error(`❌ Note document [${noteId}] not found in Firestore!`);
        return;
    }

    console.log(`✅ Note document found. Updating status to 'processing'...`);

    await noteRef.update({
        status: 'processing',
        aiStatusMessage: 'AI İşlemi başlatıldı... (Dosya indiriliyor)',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    try {
        const bucket = admin.storage().bucket(bucketName);
        const tempFilePath = `/tmp/${noteId}.m4a`;

        console.log(`⬇️ Downloading ${filePath} to ${tempFilePath}...`);
        await bucket.file(filePath).download({ destination: tempFilePath });
        const fileSize = fs.statSync(tempFilePath).size;
        console.log("✅ Audio downloaded size:", fileSize);

        await noteRef.update({
            aiStatusMessage: 'Gemini ses dosyasını dinliyor ve analiz ediyor...'
        });

        console.log("🎙 Sending audio directly to Gemini...");

        // Use standard File Management for Gemini
        // Note: For large files, we should use File API, but for simplicity in Cloud Functions 
        // with small notes, we can try inline data if small, otherwise need File API.
        // Cloud Functions memory is 1GB, limit is ~20MB for inline. 
        // If file > 20MB, we'd need the File API (uploadFile). 
        // Let's assume standard voice notes < 20MB for now or use the File Manager if package supports it easily.
        // The @google/generative-ai package supports inline data for audio.

        const audioBytes = fs.readFileSync(tempFilePath).toString("base64");

        const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" }); // Flash 2.0 is latest available

        const prompt = `
        Sen profesyonel bir İslami asistan ve transkript uzmanısın.
        Görevin bu ses dosyasını dinleyip analiz etmek.

        Lütfen SADECE aşağıdaki JSON formatında bir çıktı üret:
        {
            "transcript": "Ses kaydının tam, kelimesi kelimesine Türkçe dökümü.",
            "summary": "Konuşmanın kısa, maddeler halinde (markdown bullet points) özeti.",
            "duas": [ { "text": "Konuşmada geçen dua metni" } ]
        }
        
        Eğer konuşmada dua yoksa "duas" boş array olsun.
        `;

        const result = await model.generateContent([
            prompt,
            {
                inlineData: {
                    mimeType: "audio/mp4", // m4a is typically audio/mp4 or audio/x-m4a
                    data: audioBytes
                }
            }
        ]);

        const responseText = result.response.text();
        console.log("Gemini Audio Response Length:", responseText.length);

        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        let parsedResult;

        try {
            parsedResult = JSON.parse(jsonStr);
        } catch (e) {
            console.error("Gemini JSON Parse Error:", e);
            // Fallback attempt to salvage transcript if JSON fails
            parsedResult = {
                transcript: responseText,
                summary: "Otomatik özet oluşturulamadı (JSON hatası).",
                duas: []
            };
        }

        await noteRef.update({
            status: 'ready',
            transcriptText: parsedResult.transcript || "Transkript oluşturulamadı.",
            summaryText: parsedResult.summary || "Özet çıkarılamadı.",
            duas: parsedResult.duas || [],
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
            aiStatusMessage: null
        });

        console.log(`🎉 Successfully processed note: ${noteId} with Gemini 1.5 Flash`);

        if (fs.existsSync(tempFilePath)) {
            fs.unlinkSync(tempFilePath);
        }

    } catch (error: any) {
        console.error(`❌ Failed to process note ${noteId}:`, error);

        let errorMessage = "İşlem sırasında bilinmeyen bir hata oluştu.";
        if (error?.message) errorMessage = error.message;

        await noteRef.update({
            status: 'failed',
            aiStatusMessage: `Hata: ${errorMessage.substring(0, 200)}`
        });

        // Don't re-throw to avoid infinite retry loops in some configs, 
        // but for onFinalize it's okay.
    }
}

// ============================================
// AI Chat (Gemini)
// ============================================

export const chatWithAI = functions.runWith({
    timeoutSeconds: 60,
    memory: "512MB"
}).https.onCall(async (data, context) => {
    console.log("ChatWithAI function triggered.");
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Giriş yapmalısınız.");
    }

    const { prompt } = data;
    if (!prompt || typeof prompt !== 'string') {
        throw new functions.https.HttpsError("invalid-argument", "Geçersiz istek.");
    }

    try {
        console.log(`💬 Chat request from ${context.auth.uid}: ${prompt}`);

        const today = new Date().toLocaleDateString('tr-TR', { day: 'numeric', month: 'long', year: 'numeric' });
        const currentYear = new Date().getFullYear();

        const systemPrompt = `
        Sen 'İman Defterim AI' asistanısın. Bugünkü tarih: ${today}. Şu an ${currentYear} yılındayız.
        Samimi, İslami ve bilge bir dille, sadece Türkçe yanıt ver.
        Kullanıcının sorusuna göre YouTube'da aratılacak bir video sorgusu üret. Eğer video gerekliyse, sorgunun sonuna mutlaka "Türkçe" kelimesini ekle (örn: "Sabır duası Türkçe").
        Yanıtını SADECE şu JSON şemasında ver: { "answer": "Markdown formatlı cevap", "youtubeQuery": "YouTube arama terimi veya null" }.
        JSON dışında hiçbir şey yazma.
        `;

        const finalPrompt = `${systemPrompt}\n\nKullanıcı: ${prompt}`;

        const result = await geminiModel.generateContent(finalPrompt);
        const responseText = result.response.text();

        // Clean markdown code blocks if present
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

        console.log("Gemini Raw Response:", jsonStr);

        let aiResult;
        try {
            aiResult = JSON.parse(jsonStr);
        } catch (e) {
            console.error("JSON Parse Error:", e);
            aiResult = { answer: responseText, youtubeQuery: null };
        }

        let youtubeVideo = null;

        if (aiResult.youtubeQuery) {
            console.log(`🔎 Searching YouTube (API) for: ${aiResult.youtubeQuery}`);
            try {
                // Use Gemini API Key (often a Google Cloud Key) or fallback
                const apiKey = process.env.GEMINI_API_KEY || process.env.OPENAI_API_KEY;

                if (apiKey) {
                    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&maxResults=1&q=${encodeURIComponent(aiResult.youtubeQuery)}&type=video&key=${apiKey}`;

                    const response = await fetch(url);
                    if (!response.ok) {
                        const errText = await response.text();
                        console.error("YouTube API Error:", response.status, errText);
                        // Don't throw, just return no video to keep chat working
                    } else {
                        const searchData = await response.json();
                        // Type safety for searchData
                        if (searchData && typeof searchData === 'object' && 'items' in searchData) {
                            const items = (searchData as any).items;
                            if (Array.isArray(items) && items.length > 0) {
                                const item = items[0];
                                youtubeVideo = {
                                    id: item.id.videoId,
                                    title: item.snippet.title,
                                    thumbnailUrl: item.snippet.thumbnails.high?.url || item.snippet.thumbnails.default?.url
                                };
                            }
                        }
                    }
                } else {
                    console.warn("No API Key available for YouTube Search.");
                }

            } catch (ytError) {
                console.error("YouTube search request failed:", ytError);
            }
        }

        return {
            answer: aiResult.answer,
            video: youtubeVideo
        };

    } catch (error: any) {
        console.error("Chat error:", error);
        throw new functions.https.HttpsError("internal", "AI yanıt veremedi.");
    }
});

// ============================================
// Prayer Times
// ============================================

interface PrayerTimesData {
    imsak: string;
    gunes: string;
    ogle: string;
    ikindi: string;
    aksam: string;
    yatsi: string;
}

export const getPrayerTimes = functions.https.onCall(
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
        }

        const { plateCode, date } = data;

        if (!plateCode || plateCode < 1 || plateCode > 81) {
            throw new functions.https.HttpsError("invalid-argument", "Geçersiz il kodu");
        }

        const dateStr = date || getTodayString();
        const documentId = `${plateCode}_${dateStr}`;

        const cacheRef = db.collection("prayerTimes").doc(documentId);
        const cacheDoc = await cacheRef.get();

        if (cacheDoc.exists) {
            return cacheDoc.data();
        }

        const times = generateMockPrayerTimes(plateCode, dateStr);
        await cacheRef.set(times);

        return times;
    }
);

export const scheduledPrayerTimesCache = functions.pubsub
    .schedule("0 0 * * *")
    .timeZone("Europe/Istanbul")
    .onRun(async () => {
        console.log("Starting daily prayer times cache refresh...");

        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        const dateStr = formatDate(tomorrow);

        const majorCities = [6, 34, 35];

        for (const plateCode of majorCities) {
            const documentId = `${plateCode}_${dateStr}`;
            const times = generateMockPrayerTimes(plateCode, dateStr);

            await db.collection("prayerTimes").doc(documentId).set(times);
            console.log(`Cached prayer times for city ${plateCode}, date ${dateStr}`);
        }

        return null;
    });

// ============================================
// Notifications
// ============================================

export const sendTestNotification = functions.https.onCall(
    async (data, context) => {
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "Kullanıcı girişi gerekli");
        }
        const uid = context.auth.uid;
        const userDoc = await db.collection("users").doc(uid).get();
        const userData = userDoc.data();

        if (!userData?.fcmToken) {
            throw new functions.https.HttpsError("failed-precondition", "Bildirim token'ı bulunamadı");
        }

        const message = {
            notification: {
                title: "Vaaz Notları",
                body: "Test bildirimi başarılı!",
            },
            token: userData.fcmToken,
        };

        try {
            await admin.messaging().send(message);
            return { success: true };
        } catch (error) {
            console.error("Notification error:", error);
            throw new functions.https.HttpsError("internal", "Bildirim gönderilemedi");
        }
    }
);

// ============================================
// Helpers
// ============================================

function getTodayString(): string {
    return formatDate(new Date());
}

function formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
}

function generateMockPrayerTimes(
    plateCode: number,
    date: string
): { plateCode: number; date: string; times: PrayerTimesData; source: string; fetchedAt: admin.firestore.FieldValue } {
    const baseOffset = (plateCode - 34) * 2;
    const adjustTime = (base: string, offset: number): string => {
        const [hourStr, minStr] = base.split(":");
        let hour = parseInt(hourStr);
        let minute = parseInt(minStr) + offset;
        if (minute >= 60) {
            minute -= 60;
            hour += 1;
        } else if (minute < 0) {
            minute += 60;
            hour -= 1;
        }
        hour = Math.max(0, Math.min(23, hour));
        return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
    };

    return {
        plateCode,
        date,
        times: {
            imsak: adjustTime("06:45", baseOffset),
            gunes: adjustTime("08:15", baseOffset),
            ogle: adjustTime("13:05", baseOffset),
            ikindi: adjustTime("15:35", baseOffset),
            aksam: adjustTime("17:50", baseOffset),
            yatsi: adjustTime("19:15", baseOffset),
        },
        source: "mock",
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
}
