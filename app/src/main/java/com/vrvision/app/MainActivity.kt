package com.vrvision.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.view.Gravity
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

class MainActivity : ComponentActivity() {
    private var player: ExoPlayer? = null
    private lateinit var playerView: PlayerView
    private lateinit var status: TextView
    private var sbsMode = true

    private val pickVideo = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            try {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: Exception) { }
            playVideo(uri)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        enterImmersive()
        buildUi()
    }

    private fun enterImmersive() {
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        )
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            setPadding(16, 8, 16, 8)
        }
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val title = TextView(this).apply {
            text = "VR VISION"
            textSize = 20f
            setTextColor(Color.WHITE)
        }
        status = TextView(this).apply {
            text = "  Выбери видео"
            textSize = 13f
            setTextColor(0xFFAAAAAA.toInt())
        }
        header.addView(title)
        header.addView(status)
        root.addView(header)

        playerView = PlayerView(this).apply {
            useController = true
            setBackgroundColor(Color.BLACK)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f
            )
        }
        root.addView(playerView)

        val controls = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        controls.addView(Button(this).apply {
            text = "Открыть видео"
            setOnClickListener { pickVideo.launch(arrayOf("video/*")) }
        })
        controls.addView(Button(this).apply {
            text = "Режим: SBS"
            setOnClickListener {
                sbsMode = !sbsMode
                text = if (sbsMode) "Режим: SBS" else "Режим: Mono"
                status.text = if (sbsMode) "  Side-by-side" else "  Обычный режим"
            }
        })
        controls.addView(Button(this).apply {
            text = "VR / экран"
            setOnClickListener { enterImmersive() }
        })
        root.addView(controls)
        root.addView(TextView(this).apply {
            text = "Локальные видео • Media3 • Ландшафтный режим"
            textSize = 11f
            setTextColor(0xFF888888.toInt())
            gravity = Gravity.CENTER
        })
        setContentView(root)
    }

    private fun playVideo(uri: Uri) {
        if (player == null) {
            player = ExoPlayer.Builder(this).build().also {
                playerView.player = it
                it.addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        status.text = when (playbackState) {
                            Player.STATE_BUFFERING -> "  Загрузка…"
                            Player.STATE_READY -> "  Готово"
                            Player.STATE_ENDED -> "  Конец видео"
                            else -> "  VR Vision"
                        }
                    }
                })
            }
        }
        player?.apply {
            setMediaItem(MediaItem.fromUri(uri))
            prepare()
            playWhenReady = true
        }
        status.text = "  Видео открыто"
    }

    override fun onResume() {
        super.onResume()
        enterImmersive()
    }
    override fun onStop() {
        super.onStop()
        player?.pause()
    }
    override fun onDestroy() {
        playerView.player = null
        player?.release()
        player = null
        super.onDestroy()
    }
}
