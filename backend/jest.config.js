/** @type {import('jest').Config} */
export default {
  // Sử dụng ts-jest để chạy TypeScript
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',

  // Tìm test files trong thư mục src/
  roots: ['<rootDir>/src'],

  // Pattern nhận diện file test
  testMatch: [
    '**/__tests__/**/*.test.ts',
    '**/*.test.ts',
    '**/*.spec.ts',
  ],

  // Module name mapping (cho ESM imports)
  moduleNameMapper: {
    '^(\\.{1,2}/.*)\\.js$': '$1',
  },

  // Transform TypeScript
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        useESM: true,
        tsconfig: 'tsconfig.json',
      },
    ],
  },

  // Coverage config
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/generated/**',
    '!src/index.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'text-summary', 'lcov', 'clover'],
};
