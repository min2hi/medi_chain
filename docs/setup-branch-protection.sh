#!/bin/bash
# ============================================================
# MediChain — Branch Protection Setup via GitHub CLI
# ============================================================
# Script này cài đặt Branch Protection Rules cho repo tự động.
# Thay vì vào GitHub UI bấm từng ô, chạy script này 1 lần là xong.
#
# YÊU CẦU:
#   1. Cài GitHub CLI: https://cli.github.com/
#   2. Đăng nhập: gh auth login
#   3. Chạy script: bash docs/setup-branch-protection.sh
#
# GHI CHÚ: Chạy 1 lần duy nhất sau khi tạo repo. Không cần lại.
# ============================================================

OWNER="min2hi"
REPO="medi_chain"

echo "🔒 Setting up branch protection for $OWNER/$REPO..."

# ─── BẢO VỆ NHÁNH MAIN ───────────────────────────────────────
# Đây là nhánh production — cần bảo vệ mạnh nhất
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$REPO/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "🔐 Security Scan (Gitleaks)",
      "🔧 Backend Check",
      "🎨 Frontend Check"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true
}
EOF

echo "✅ main branch protected!"

# ─── BẢO VỆ NHÁNH DEVELOP ────────────────────────────────────
# Nhánh staging — bảo vệ nhẹ hơn main (không cần PR review)
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$REPO/branches/develop/protection" \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "🔐 Security Scan (Gitleaks)",
      "🔧 Backend Check",
      "🎨 Frontend Check"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": false
}
EOF

echo "✅ develop branch protected!"
echo ""
echo "📋 Summary:"
echo "  main   → Require CI pass ✅ | Require 1 PR review ✅ | No force push ✅"
echo "  develop → Require CI pass ✅ | No force push ✅"
echo ""
echo "🔗 Verify tại: https://github.com/$OWNER/$REPO/settings/branches"
