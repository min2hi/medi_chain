package com.medichain.medi_chain_mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth yêu cầu FlutterFragmentActivity (không dùng FlutterActivity)
// vì BiometricPrompt cần FragmentManager để hiện dialog xác thực
class MainActivity : FlutterFragmentActivity()
