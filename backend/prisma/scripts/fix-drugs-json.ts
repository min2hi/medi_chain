import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const drugsPath = resolve(__dirname, '../seed-data', 'drugs.json');

console.log('Reading drugs.json...');
const lines = readFileSync(drugsPath, 'utf-8').split('\n');

console.log(`Processing ${lines.length} lines...`);
const outputLines: string[] = [];
let fixedCount = 0;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  // Check if this line is a string property line
  // e.g.     "sideEffects": "some value",  or    "sideEffects": "some value"
  const match = line.match(/^(\s*"[a-zA-Z0-9]+"\s*:\s*")([\s\S]*)("[a-zA-Z0-9\-\:\.\,\s]*)$/);
  
  if (match) {
    const prefix = match[1]; // e.g. '    "sideEffects": "'
    const valuePart = match[2]; // the value inside quotes
    const suffix = match[3]; // e.g. '",' or '"'
    
    // We want to escape any double quotes inside valuePart that are not already escaped
    // A double quote is unescaped if it is not preceded by a backslash.
    // However, JS regex replace can be tricky with negative lookbehind, so we can do it manually or via regex:
    // We can replace any " that is not preceded by \.
    // Let's do it by replacing all backslashes and quotes:
    let escapedValue = '';
    for (let j = 0; j < valuePart.length; j++) {
      const char = valuePart[j];
      if (char === '"') {
        // check if previous char was backslash
        if (j > 0 && valuePart[j - 1] === '\\') {
          escapedValue += char;
        } else {
          escapedValue += '\\"';
          fixedCount++;
        }
      } else {
        escapedValue += char;
      }
    }
    
    outputLines.push(prefix + escapedValue + suffix);
  } else {
    outputLines.push(line);
  }
}

console.log(`Escaped ${fixedCount} double quotes.`);
const newContent = outputLines.join('\n');

try {
  JSON.parse(newContent);
  console.log('JSON parsed successfully!');
  writeFileSync(drugsPath, newContent, 'utf-8');
  console.log('drugs.json fixed and saved.');
} catch (e: any) {
  console.error('JSON parsing failed:', e.message);
  // Find where it failed
  const match = e.message.match(/at position (\d+)/);
  if (match) {
    const pos = parseInt(match[1], 10);
    const start = Math.max(0, pos - 100);
    const end = Math.min(newContent.length, pos + 100);
    console.log('Context around error:');
    console.log(newContent.substring(start, end));
  }
}
