
const fs = require('fs');
const path = require('path');

async function listModels() {
    try {
        // Manually read .env
        const envPath = path.resolve(__dirname, '.env');
        if (!fs.existsSync(envPath)) {
            console.error(".env file not found!");
            return;
        }

        const envContent = fs.readFileSync(envPath, 'utf8');
        const match = envContent.match(/GEMINI_API_KEY=(.*)/);

        if (!match || !match[1]) {
            console.error("GEMINI_API_KEY not found in .env");
            return;
        }

        const apiKey = match[1].trim();
        console.log("API Key found (starts with):", apiKey.substring(0, 5) + "...");

        console.log("Fetching models...");
        const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;

        const response = await fetch(url);

        if (!response.ok) {
            console.error("HTTP Error:", response.status, await response.text());
            return;
        }

        const data = await response.json();

        if (data.models) {
            console.log("\nAvailable Models:");
            data.models.forEach(m => console.log(`- ${m.name}`));
        } else {
            console.log("No models returned.");
        }

    } catch (e) {
        console.error("Error:", e);
    }
}

listModels();
