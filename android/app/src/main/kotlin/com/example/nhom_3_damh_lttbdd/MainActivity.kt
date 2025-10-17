package com.example.nhom_3_damh_lttbdd

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.util.Base64
import android.util.Log
import android.content.pm.PackageManager
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        printHashKey()
    }

    private fun printHashKey() {
        try {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
            info.signatures?.forEach { signature ->
                val md = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                val hashKey = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                Log.d("FacebookKeyHash", "Key Hash: $hashKey")
            }
        } catch (e: Exception) {
            Log.e("FacebookKeyHash", "Error getting hash: ${e.message}")
        }
    }
}