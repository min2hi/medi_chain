import { describe, it, expect } from '@jest/globals';
import { HealthTwinService } from './health-twin.service.js';

describe('HealthTwinService - _checkAbsoluteThresholds', () => {
    const checkThresholds = (HealthTwinService as any)._checkAbsoluteThresholds;

    it('should return null for normal vitals', () => {
        const result = checkThresholds('Huyết áp: 120/80 mmHg, nhịp tim: 75 bpm, nhiệt độ: 36.5 °C, SpO2: 98%');
        expect(result).toBeNull();
    });

    it('should detect low SpO2 as severe anomaly', () => {
        const result = checkThresholds('Chỉ số đo được: SpO2 91%');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(8);
        expect(result!.reason).toContain('suy hô hấp');
    });

    it('should detect high blood pressure', () => {
        const result = checkThresholds('Huyết áp tâm thu cao: 145/92 mmHg');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(7);
        expect(result!.reason).toContain('Huyết áp cao');
    });

    it('should detect low blood pressure', () => {
        const result = checkThresholds('Chỉ số HA đo lúc sáng: 85/55 mmHg');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(7);
        expect(result!.reason).toContain('Huyết áp thấp');
    });

    it('should detect high heart rate (tachycardia)', () => {
        const result = checkThresholds('Nhịp tim đo được: 112 bpm');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(6);
        expect(result!.reason).toContain('nhịp tim nhanh');
    });

    it('should detect low heart rate (bradycardia)', () => {
        const result = checkThresholds('Nhịp tim đập chậm: 48 nhịp/phút');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(6);
        expect(result!.reason).toContain('nhịp tim chậm');
    });

    it('should detect high fever', () => {
        const result = checkThresholds('Bệnh nhân đang bị sốt cao: 39.2 °C');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(7);
        expect(result!.reason).toContain('sốt cao');
    });

    it('should detect low body temperature', () => {
        const result = checkThresholds('Nhiệt độ cơ thể bị hạ: 34.5 độ c');
        expect(result).not.toBeNull();
        expect(result!.severity).toBe(7);
        expect(result!.reason).toContain('hạ thân nhiệt');
    });
});
