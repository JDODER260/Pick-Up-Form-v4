package com.doublersharpening.pick_up_app_v4

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channel_name = "apk_installer"

    override fun configureFlutterEngine(flutter_engine: FlutterEngine) {
        super.configureFlutterEngine(flutter_engine)

        MethodChannel(
            flutter_engine.dartExecutor.binaryMessenger,
            channel_name
        ).setMethodCallHandler { call, result ->
            if (call.method == "install_apk") {
                val file_path = call.argument<String>("file_path")
                if (file_path == null) {
                    result.error("NO_PATH", "APK path missing", null)
                    return@setMethodCallHandler
                }
                install_apk(file_path)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun install_apk(file_path: String) {
        val file = File(file_path)
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }
}
