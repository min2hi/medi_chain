import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Tạo standalone bundle tối ưu cho Docker deployment
  // Output: .next/standalone — chứa mọi thứ để chạy, không cần node_modules đầy đủ
  // Giảm image size từ ~1GB xuống ~150MB
  output: 'standalone',
};

export default nextConfig;
