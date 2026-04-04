/**
 * Test script cho MediChain AI API
 * Chạy: node test-ai-api.js (hoặc dùng ts-node)
 */

const API_URL = 'http://localhost:3000/api/chat';

// Test 1: Basic chat request
async function testBasicChat() {
    console.log('\n🧪 Test 1: Basic Chat Request');
    console.log('━'.repeat(50));

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Xin chào, tôi bị đau đầu. Nên làm gì?'
            })
        });

        const data = await response.json();

        console.log('Status:', response.status);
        console.log('Rate Limit Remaining:', response.headers.get('X-RateLimit-Remaining'));

        if (response.ok) {
            console.log('✅ Success!');
            console.log('AI Response:', data.choices[0].message.content);
            console.log('Token Usage:', data.usage);
        } else {
            console.log('❌ Error:', data.error);
        }
    } catch (error) {
        console.error('❌ Request failed:', error.message);
    }
}

// Test 2: Rate limiting
async function testRateLimit() {
    console.log('\n🧪 Test 2: Rate Limiting (11 requests)');
    console.log('━'.repeat(50));

    let successCount = 0;
    let rateLimitedCount = 0;

    for (let i = 1; i <= 11; i++) {
        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: `Test message ${i}`
                })
            });

            const remaining = response.headers.get('X-RateLimit-Remaining');

            if (response.status === 429) {
                const data = await response.json();
                console.log(`Request ${i}: ⚠️  Rate limited - ${data.message}`);
                rateLimitedCount++;
            } else if (response.ok) {
                console.log(`Request ${i}: ✅ Success (${remaining} remaining)`);
                successCount++;
            } else {
                console.log(`Request ${i}: ❌ Error ${response.status}`);
            }

            // Delay nhỏ giữa các requests
            await new Promise(resolve => setTimeout(resolve, 100));

        } catch (error) {
            console.error(`Request ${i}: ❌ Failed:`, error.message);
        }
    }

    console.log('\nResults:');
    console.log(`✅ Success: ${successCount}`);
    console.log(`⚠️  Rate Limited: ${rateLimitedCount}`);
}

// Test 3: Input validation
async function testValidation() {
    console.log('\n🧪 Test 3: Input Validation');
    console.log('━'.repeat(50));

    const testCases = [
        { message: '', expected: 400, desc: 'Empty message' },
        { message: '   ', expected: 400, desc: 'Whitespace only' },
        { message: 'a'.repeat(3000), expected: 400, desc: 'Too long message' },
    ];

    for (const test of testCases) {
        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: test.message })
            });

            const data = await response.json();

            if (response.status === test.expected) {
                console.log(`✅ ${test.desc}: Correctly rejected (${response.status})`);
            } else {
                console.log(`❌ ${test.desc}: Expected ${test.expected}, got ${response.status}`);
            }

        } catch (error) {
            console.error(`❌ ${test.desc}: Request failed:`, error.message);
        }

        await new Promise(resolve => setTimeout(resolve, 100));
    }
}

// Test 4: Health check
async function testHealthCheck() {
    console.log('\n🧪 Test 4: Health Check');
    console.log('━'.repeat(50));

    try {
        const response = await fetch(API_URL, {
            method: 'GET'
        });

        const data = await response.json();

        console.log('Status:', response.status);
        console.log('Response:', data);

        if (response.ok && data.status === 'ok') {
            console.log('✅ Health check passed!');
        } else {
            console.log('❌ Health check failed');
        }
    } catch (error) {
        console.error('❌ Health check failed:', error.message);
    }
}

// Test 5: With authentication
async function testWithAuth() {
    console.log('\n🧪 Test 5: Authenticated Request');
    console.log('━'.repeat(50));

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer test_token_123'
            },
            body: JSON.stringify({
                message: 'Authenticated request test'
            })
        });

        const data = await response.json();

        console.log('Status:', response.status);

        if (response.ok) {
            console.log('✅ Authenticated request successful');
            console.log('Rate Limit ID:', 'user:test_token');
        } else {
            console.log('❌ Error:', data.error);
        }
    } catch (error) {
        console.error('❌ Request failed:', error.message);
    }
}

// Main test runner
async function runAllTests() {
    console.log('\n' + '='.repeat(50));
    console.log('🚀 MediChain AI API Test Suite');
    console.log('='.repeat(50));

    await testHealthCheck();
    await testBasicChat();

    // Đợi một chút trước khi test validation
    console.log('\n⏳ Waiting 2s before validation tests...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    await testValidation();

    // Đợi một chút trước khi test auth
    console.log('\n⏳ Waiting 2s before auth test...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    await testWithAuth();

    // Đợi rate limit reset trước khi test rate limiting
    console.log('\n⏳ Waiting 60s for rate limit reset...');
    console.log('(Bấm Ctrl+C để skip test rate limiting)');
    await new Promise(resolve => setTimeout(resolve, 60000));

    await testRateLimit();

    console.log('\n' + '='.repeat(50));
    console.log('✅ All tests completed!');
    console.log('='.repeat(50) + '\n');
}

// Chọn test muốn chạy
const args = process.argv.slice(2);

if (args.includes('--quick')) {
    // Quick test (không có rate limit test)
    (async () => {
        await testHealthCheck();
        await testBasicChat();
        await testValidation();
    })();
} else if (args.includes('--rate-limit')) {
    testRateLimit();
} else if (args.includes('--all')) {
    runAllTests();
} else {
    console.log(`
MediChain AI API Test Script

Usage:
  node test-ai-api.js --quick        # Quick tests
  node test-ai-api.js --rate-limit   # Test rate limiting only
  node test-ai-api.js --all          # Run all tests (slow)

Examples:
  node test-ai-api.js --quick
  `);
}
