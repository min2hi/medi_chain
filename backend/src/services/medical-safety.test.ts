import { describe, it, expect } from '@jest/globals';
import { MedicalSafetyService } from './medical-safety.service.js';

describe('MedicalSafetyService - checkDrugInteractions', () => {
    it('should return no warnings if currentMedicines is empty', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions([]);
        expect(warnings).toEqual([]);
    });

    it('should return no warnings if no drug interactions exist', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Panadol', 'Vitamin C']);
        expect(warnings).toEqual([]);
    });

    it('should catch standard drug interactions (warfarin + aspirin)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Warfarin', 'Aspirin']);
        expect(warnings).toHaveLength(2); // warfarin interacts with aspirin AND aspirin interacts with warfarin
        expect(warnings[0]).toContain('tương tác');
    });

    it('should catch localized Vietnamese drug interactions (Metronidazole + rượu)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Metronidazole', 'uống rượu bia']);
        expect(warnings).toHaveLength(1);
        expect(warnings[0]).toContain('Metronidazole');
        expect(warnings[0]).toContain('uống rượu bia');
    });

    it('should catch critical cardiovascular drug interactions (Sildenafil + Nitroglycerin)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Sildenafil 50mg', 'Nitroglycerin spray']);
        expect(warnings).toHaveLength(1);
        expect(warnings[0]).toContain('Sildenafil');
        expect(warnings[0]).toContain('Nitroglycerin');
    });

    it('should catch local herbal drug interactions (Sintrom + Hoạt huyết dưỡng não)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Sintrom', 'Hoạt huyết dưỡng não']);
        expect(warnings).toHaveLength(2); // sintrom -> hoạt huyết dưỡng não AND hoạt huyết dưỡng não -> sintrom
        expect(warnings[0]).toContain('Sintrom');
        expect(warnings[0]).toContain('Hoạt huyết dưỡng não');
    });

    it('should catch critical antibiotic-statin interactions (Clarithromycin + Simvastatin)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Clarithromycin 500mg', 'Simvastatin 20mg']);
        expect(warnings).toHaveLength(1);
        expect(warnings[0]).toContain('Clarithromycin');
        expect(warnings[0]).toContain('Simvastatin');
    });

    it('should not flag unrelated medications as interacting (Aspirin + Vitamin C)', () => {
        const warnings = MedicalSafetyService.checkDrugInteractions(['Aspirin', 'Vitamin C']);
        // Aspirin has potential interactions in the system but not with Vitamin C specifically.
        // It must check that the presence of an interactable drug does not trigger warnings unless paired correctly.
        expect(warnings).toEqual([]);
    });
});
