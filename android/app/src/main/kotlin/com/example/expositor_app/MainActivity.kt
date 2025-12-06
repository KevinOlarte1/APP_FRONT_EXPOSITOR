package com.example.expositor_app

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.expositor_app/files"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "saveToDownloads") {
                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("filename")

                if (bytes == null || filename == null) {
                    result.error("INVALID", "Missing bytes or filename", null)
                    return@setMethodCallHandler
                }

                try {
                    val uri = saveFile(this, bytes, filename)
                    result.success(uri.toString())
                } catch (e: Exception) {
                    result.error("ERROR", e.toString(), null)
                }
            }
        }
    }

    private fun saveFile(context: Context, bytes: ByteArray, filename: String): Uri {

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // ANDROID 10+
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, filename)
                put(MediaStore.Downloads.MIME_TYPE, "text/csv")
            }

            val uri = context.contentResolver.insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values
            ) ?: throw Exception("Failed to create file")

            context.contentResolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
            }

            uri

        } else {
            // ANDROID 9 O INFERIOR → Ruta correcta y universal
            val downloads = File("/storage/emulated/0/Download")
            if (!downloads.exists()) downloads.mkdirs()

            val file = File(downloads, filename)
            val output: OutputStream = FileOutputStream(file)
            output.write(bytes)
            output.close()

            return Uri.fromFile(file)
        }
    }
}
