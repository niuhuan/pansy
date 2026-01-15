package opensource.pansy

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {

    private val pool = Executors.newCachedThreadPool { runnable ->
        Thread(runnable).also { it.isDaemon = true }
    }
    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private val notImplementedToken = Any()
    private fun MethodChannel.Result.withCoroutine(exec: () -> Any?) {
        pool.submit {
            try {
                val data = exec()
                uiThreadHandler.post {
                    when (data) {
                        notImplementedToken -> {
                            notImplemented()
                        }
                        is Unit, null -> {
                            success(null)
                        }
                        else -> {
                            success(data)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("Method", "Exception", e)
                uiThreadHandler.post {
                    error("", e.message, "")
                }
            }

        }
    }

    @RequiresApi(Build.VERSION_CODES.KITKAT)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cross").setMethodCallHandler { call, result ->
            result.withCoroutine {
                when (call.method) {
                    "androidGetVersion" -> Build.VERSION.SDK_INT
                    "root" -> context!!.filesDir.absolutePath
                    "saveImageToGallery" -> {
                        val path = call.argument<String>("path") ?: return@withCoroutine false
                        saveImageToGallery(path)
                    }
                    "saveFileToDownloads" -> {
                        val path = call.argument<String>("path") ?: return@withCoroutine null
                        val fileName = call.argument<String>("fileName") ?: return@withCoroutine null
                        val subDir = call.argument<String>("subDir") ?: "Pansy"
                        saveFileToDownloads(path, fileName, subDir)
                    }
                    else -> {
                        notImplementedToken
                    }
                }
            }
        }
    }

    private fun saveImageToGallery(path: String): Boolean {
        val src = File(path)
        if (!src.exists()) return false

        val ext = src.extension.lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "image/jpeg"
        val name = if (src.nameWithoutExtension.isNotEmpty()) src.name else "pansy_${System.currentTimeMillis()}.$ext"

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, mime)
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    Environment.DIRECTORY_PICTURES + File.separator + "Pansy"
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: return false
            try {
                resolver.openOutputStream(uri)?.use { out ->
                    FileInputStream(src).use { input -> input.copyTo(out) }
                } ?: return false
                values.clear()
                values.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                true
            } catch (e: Exception) {
                try { resolver.delete(uri, null, null) } catch (_: Exception) {}
                false
            }
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                "Pansy"
            )
            if (!dir.exists()) dir.mkdirs()
            val target = File(dir, name)
            try {
                src.copyTo(target, overwrite = false)
            } catch (_: Exception) {
                return false
            }
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(target.absolutePath),
                arrayOf(mime),
                null
            )
            true
        }
    }

    private fun saveFileToDownloads(path: String, fileName: String, subDir: String): String? {
        val src = File(path)
        if (!src.exists()) return null

        val ext = src.extension.lowercase()
        val mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "application/octet-stream"
        val cleanSubDir = subDir.replace(Regex("""[\\:*?"<>|]"""), "_").trim().ifEmpty { "Pansy" }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mime)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + File.separator + cleanSubDir)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: return null
            try {
                resolver.openOutputStream(uri)?.use { out ->
                    FileInputStream(src).use { input -> input.copyTo(out) }
                } ?: return null
                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                uri.toString()
            } catch (e: Exception) {
                try { resolver.delete(uri, null, null) } catch (_: Exception) {}
                null
            }
        } else {
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), cleanSubDir)
            if (!dir.exists()) dir.mkdirs()
            val target = File(dir, fileName)
            return try {
                src.copyTo(target, overwrite = false)
                MediaScannerConnection.scanFile(
                    applicationContext,
                    arrayOf(target.absolutePath),
                    arrayOf(mime),
                    null
                )
                target.absolutePath
            } catch (_: Exception) {
                null
            }
        }
    }

}
