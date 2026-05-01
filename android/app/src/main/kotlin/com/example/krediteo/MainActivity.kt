package com.example.krediteo

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.krediteo/call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "makeDirectCall") {
                val phoneNumber = call.argument<String>("number")
                if (phoneNumber != null) {
                    val success = makeDirectCall(phoneNumber)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("CALL_FAILED", "Could not initiate call", null)
                    }
                } else {
                    result.error("INVALID_NUMBER", "Phone number is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun makeDirectCall(phoneNumber: String): Boolean {
        return try {
            // Seul le '#' doit impérativement être encodé pour Uri.parse dans un intent tel:
            // L'encodage complet via Uri.encode peut parfois transformer '*' en '%2A'
            // ce qui n'est pas toujours bien interprété par l'application Téléphone de certains constructeurs.
            val encodedNumber = phoneNumber.replace("#", Uri.encode("#"))
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$encodedNumber")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
