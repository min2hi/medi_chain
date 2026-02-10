import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

async function listModels() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        console.error('GEMINI_API_KEY is not set');
        return;
    }

    // Attempt with different configurations
    const configs = [
        { model: 'gemini-1.5-flash' },
        { model: 'gemini-1.5-flash', apiVersion: 'v1' },
        { model: 'gemini-pro', apiVersion: 'v1' },
        { model: 'gemini-1.5-flash-latest' }
    ];

    for (const config of configs) {
        console.log(`\n--- Testing: ${JSON.stringify(config)} ---`);
        try {
            // @ts-ignore
            const genAI = new GoogleGenerativeAI(apiKey);
            // @ts-ignore
            const model = genAI.getGenerativeModel({ model: config.model }, { apiVersion: config.apiVersion });
            const result = await model.generateContent('Hi');
            console.log('Success:', result.response.text());
            break; // Stop if one works
        } catch (error: any) {
            console.error('Failed:', error.message);
        }
    }
}

listModels();
