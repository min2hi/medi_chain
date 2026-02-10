import dotenv from 'dotenv';
dotenv.config();

async function testRaw() {
    const apiKey = process.env.GEMINI_API_KEY;
    const url = `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

    console.log('Testing raw fetch to gemini-1.5-flash (v1)...');
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contents: [{ parts: [{ text: 'hi' }] }]
            })
        });
        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Data:', JSON.stringify(data, null, 2));
    } catch (e: any) {
        console.error('Fetch error:', e.message);
    }
}

testRaw();
