// commitlint.config.cjs
// ============================================================
// Enforce Conventional Commits format tự động.
// File này được đọc bởi commitlint khi bạn chạy `git commit`.
//
// TẠI SAO CẦN FILE NÀY?
//   - .gitignore chỉ ngăn file bị commit — không ngăn được
//     commit message sai format.
//   - Nếu message sai format → Release-Please không thể tự động
//     tạo Changelog và bump version.
//   - Enforce tự động → không cần "nhờ" dev nhớ convention.
//
// FORMAT HỢP LỆ:
//   feat(backend): thêm endpoint mới
//   fix(mobile): sửa crash khi logout
//   docs: cập nhật README
//   chore(deps): update dependencies
//
// FORMAT KHÔNG HỢP LỆ (sẽ bị chặn):
//   "fix bug"               ← thiếu type
//   "FEAT: add login"       ← type phải lowercase
//   "feat: "                ← thiếu description
// ============================================================

module.exports = {
  extends: ['@commitlint/config-conventional'],

  rules: {
    // Type phải là một trong danh sách này
    'type-enum': [
      2, // 2 = error (chặn commit)
      'always',
      [
        'feat',     // Tính năng mới
        'fix',      // Sửa bug
        'refactor', // Tái cấu trúc (không thêm feature, không fix bug)
        'chore',    // Bảo trì: update deps, config, gitignore
        'docs',     // Chỉ sửa documentation
        'test',     // Thêm hoặc sửa test
        'perf',     // Cải thiện hiệu năng
        'style',    // Format, spacing (không ảnh hưởng logic)
        'ci',       // Thay đổi CI/CD config
        'revert',   // Revert commit trước
      ],
    ],

    // Type phải viết thường: feat, fix, ... (không phải FEAT, Fix)
    'type-case': [2, 'always', 'lower-case'],

    // Description không được để trống
    'subject-empty': [2, 'never'],

    // Description không được kết thúc bằng dấu chấm
    'subject-full-stop': [2, 'never', '.'],

    // Header (dòng đầu) không quá 100 ký tự
    'header-max-length': [2, 'always', 100],

    // Body (nếu có) phải ngăn cách với header bằng 1 dòng trống
    'body-leading-blank': [1, 'always'], // 1 = warning (không chặn)

    // Footer (nếu có) phải ngăn cách với body bằng 1 dòng trống
    'footer-leading-blank': [1, 'always'],
  },
};
