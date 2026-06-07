export interface ParsedMedicine {
  name: string;
  dosage: string;
  frequency: string;
  instruction: string;
  durationDays?: number | null;
}

export class PrescriptionParser {
  // ── Từ khóa cần bỏ qua (header/footer đơn thuốc) ─────────────────────────
  private static readonly skipKeywords = [
    'bác sĩ', 'bac si', 'phòng khám', 'phong kham',
    'bệnh viện', 'benh vien', 'họ tên', 'ho ten',
    'địa chỉ', 'dia chi', 'chẩn đoán', 'chan doan',
    'chuẩn đoán', 'khám', 'tái khám', 'tai kham',
    'chữ ký', 'chu ky', 'đơn thuốc', 'don thuoc',
    'hướng dẫn', 'huong dan', 'lưu ý', 'luu y',
    'bs.', 'bs ', 'dr.', 'dr ', 'rx:', 'đơn số', 'ngày khám',
    'tuổi', 'tuoi', 'giới tính', 'gioi tinh',
  ];

  // ── Từ khóa instruction (không phải tên thuốc) ────────────────────────────
  private static readonly instrWords = [
    'uống', 'uong', 'dùng', 'dung', 'sau', 'trước', 'truoc',
    'sáng', 'sang', 'chiều', 'chieu', 'tối', 'toi', 'trưa', 'trua',
    'viên', 'vien', 'gói', 'goi', 'ống', 'ong', 'lần', 'lan',
    'ngày', 'ngay', 'trong', 'khi', 'bữa', 'bua', 'ăn', 'an',
    'buổi', 'buoi',
  ];

  // ── Patterns ──────────────────────────────────────────────────────────────
  private static readonly rxNameLine = /^(?:\d+[\.\)]\s*)?([A-ZÀ-Ỹa-zà-ỹ][A-Za-zÀ-ỹà-ỹ0-9\s\-]+?)(?:\s*(\d+(?:[,.]\d+)?\s*(?:mg|mcg|g|ml|IU|đv|%)(?:\/\d+\s*(?:ml|g))?))?\s*$/i;

  private static readonly rxDosage = /(\d+(?:[,.]\d+)?)\s*(viên|vien|gói|goi|ống|ong|ml|mg|mcg|g|giọt|giot|thìa|thia)/i;

  private static readonly rxFreqNumeric = /(?:(\d+)\s*(?:l[aầ]n|vien|viên)\s*[\/x×]\s*ng[aà]y)|(?:(\d+)\s*(?:l[aầ]n|vien|viên)\s*m[oỗ]i\s*ng[aà]y)|(?:(\d+)\s*(?:vien|viên|goi|gói)\s*\/\s*ng[aà]y)/i;

  private static readonly rxSession = /\b(s[aá]ng|chi[eề]u|t[oố]i|tr[uư]a)\b/gi;

  private static readonly rxDuration = /(\d+)\s*(ng[aà]y|tu[aầ]n|th[aá]ng)/i;

  private static readonly rxInstruction = /(sau\s*(?:khi\s*)?[aă]n|tr[uư][oớ]c\s*(?:khi\s*)?[aă]n|trong\s*b[uữ]a\s*[aă]n|l[uú]c\s*[dđ][oó]i|khi\s*[dđ]i\s*ng[uủ])/i;

  public static parse(ocrText: string): ParsedMedicine[] {
    const lines = this.cleanLines(ocrText);
    if (lines.length === 0) return [];

    // Ưu tiên parse theo số thứ tự
    const numbered = this.parseNumbered(lines);
    if (numbered.length > 0) return numbered;

    // Fallback: parse theo block tên thuốc
    return this.parseByMedicineLine(lines);
  }

  private static parseNumbered(lines: string[]): ParsedMedicine[] {
    const groups: string[][] = [];
    let current: string[] = [];

    const numberedRx = /^\d+[\.\)]\s+\S/;

    for (const line of lines) {
      if (numberedRx.test(line)) {
        if (current.length > 0) groups.push([...current]);
        current = [line];
      } else if (current.length > 0) {
        current.push(line);
      }
    }
    if (current.length > 0) groups.push(current);
    if (groups.length === 0) return [];

    return groups
      .map((g) => this.parseGroup(g))
      .filter((m): m is ParsedMedicine => m !== null);
  }

  private static parseByMedicineLine(lines: string[]): ParsedMedicine[] {
    const results: ParsedMedicine[] = [];

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (this.isSkipLine(line)) continue;
      if (this.isInstructionLine(line)) continue;

      let nd = this.extractNameAndDosage(line);
      if (!nd) nd = this.extractNameFromInlineLine(line);

      if (!nd) continue;

      const body: string[] = [];
      for (let j = i + 1; j < lines.length && j <= i + 3; j++) {
        const nextNd = this.extractNameAndDosage(lines[j]) || this.extractNameFromInlineLine(lines[j]);
        if (nextNd && !this.isInstructionLine(lines[j])) break;
        body.push(lines[j]);
      }

      const allText = [line, ...body].join(' ');
      results.push(this.buildMedicine(nd.name, nd.dosage, allText));
    }
    return results;
  }

  private static extractNameFromInlineLine(line: string): { name: string; dosage: string } | null {
    const words = line.trim().split(/\s+/);
    if (words.length === 0) return null;

    const nameWords: string[] = [];
    let dosage = '';

    const rxDosageLimit = /^\d+(?:[,.]\d+)?\s*(?:mg|mcg|g|ml|IU|%)/i;

    for (let i = 0; i < words.length; i++) {
      const w = words[i].toLowerCase();

      if (this.instrWords.includes(w)) break;

      if (rxDosageLimit.test(words[i])) {
        dosage = words[i];
        break;
      }

      if (/^\d/.test(w) && nameWords.length > 0) break;

      nameWords.push(words[i]);
    }

    if (nameWords.length === 0 || nameWords.length > 5) return null;
    const name = nameWords.join(' ');
    if (name.length < 3) return null;

    return { name, dosage };
  }

  private static parseGroup(group: string[]): ParsedMedicine | null {
    if (group.length === 0) return null;
    const header = group[0];
    if (this.isSkipLine(header)) return null;

    const stripped = header.replace(/^\d+[\.\)]\s*/, '').trim();
    const nd = this.extractNameAndDosage(stripped);
    if (!nd) return null;

    const allText = group.join(' ');
    return this.buildMedicine(nd.name, nd.dosage, allText);
  }

  private static buildMedicine(name: string, dosageHint: string, allText: string): ParsedMedicine {
    const dosageMatch = allText.match(this.rxDosage);
    const dosage = dosageHint.length > 0
      ? dosageHint
      : (dosageMatch ? dosageMatch[0] : '');

    const frequency = this.extractFrequency(allText);
    const durationDays = this.extractDuration(allText);
    const instruction = this.extractInstruction(allText);

    return {
      name: this.capitalizeName(name),
      dosage,
      frequency,
      instruction,
      durationDays,
    };
  }

  private static extractNameAndDosage(line: string): { name: string; dosage: string } | null {
    const m = line.trim().match(this.rxNameLine);
    if (!m) return null;

    const name = m[1]?.trim() || '';
    const dosage = m[2]?.trim() || '';

    if (name.length < 3) return null;
    if (name.split(' ').length > 5) return null;

    const nameLower = name.toLowerCase();
    const wordList = nameLower.split(/\s+/);
    const instrHits = wordList.filter((w) => this.instrWords.includes(w)).length;
    if (instrHits >= 1) return null;

    return { name, dosage };
  }

  private static extractFrequency(text: string): string {
    const numericMatch = text.match(this.rxFreqNumeric);
    if (numericMatch) return numericMatch[0].trim();

    const sessions = new Set<string>();
    let m;
    // Reset global regex index
    this.rxSession.lastIndex = 0;
    while ((m = this.rxSession.exec(text)) !== null) {
      const s = m[1].toLowerCase();
      if (s.startsWith('s')) sessions.add('Sáng');
      else if (s.startsWith('tr')) sessions.add('Trưa');
      else if (s.startsWith('ch') || s.startsWith('c')) sessions.add('Chiều');
      else if (s.startsWith('t')) sessions.add('Tối');
    }

    const order = ['Sáng', 'Trưa', 'Chiều', 'Tối'];
    const sorted = order.filter((x) => sessions.has(x));
    if (sorted.length > 0) return sorted.join(' - ');

    return '';
  }

  private static extractDuration(text: string): number | null {
    const m = text.match(this.rxDuration);
    if (!m) return null;
    const val = parseInt(m[1] || '0', 10);
    const unit = m[2].toLowerCase();
    if (unit.startsWith('tu')) return val * 7;
    if (unit.startsWith('th')) return val * 30;
    return val;
  }

  private static extractInstruction(text: string): string {
    const m = text.match(this.rxInstruction);
    if (!m) return '';
    const raw = m[0] || '';
    return raw.length === 0 ? '' : raw[0].toUpperCase() + raw.substring(1);
  }

  private static isSkipLine(line: string): boolean {
    const lower = line.toLowerCase();
    return this.skipKeywords.some((kw) => lower.includes(kw));
  }

  private static isInstructionLine(line: string): boolean {
    const lower = line.toLowerCase();
    const firstWord = lower.split(/\s+/)[0];
    return this.instrWords.includes(firstWord);
  }

  private static cleanLines(text: string): string[] {
    return text
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 2);
  }

  private static capitalizeName(s: string): string {
    return s
      .split(' ')
      .map((w) => w.length === 0 ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
  }
}
