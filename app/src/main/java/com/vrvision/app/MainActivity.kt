package com.vrvision.app

import android.app.AlertDialog
import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RenderEffect
import android.graphics.RuntimeShader
import android.os.Build
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.*
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.PlaybackException
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import kotlin.math.min

class MainActivity : ComponentActivity() {
    private var leftPlayer: ExoPlayer? = null
    private var rightPlayer: ExoPlayer? = null
    private lateinit var leftView: PlayerView
    private lateinit var rightView: PlayerView
    private lateinit var stage: FrameLayout
    private lateinit var controlsPanel: LinearLayout
    private var controlsVisible = true
    private val hideControlsTask = Runnable { hideControls() }
    private lateinit var status: TextView
    private lateinit var overlay: CalibrationOverlay
    private lateinit var modeButton: Button
    private lateinit var maskButton: Button
    private var sbs = false
    private var grid = false
    private var mask = 0 // 0 none, 1 round, 2 oval, 3 rounded rectangle
    private var zoom = 1.0f
    private var eyeOffset = 0.0f
    private var leftEyeX = 0.0f
    private var rightEyeX = 0.0f
    private var leftEyeY = 0.0f
    private var rightEyeY = 0.0f
    private var leftEyeScale = 1.0f
    private var rightEyeScale = 1.0f
    private var calibrationPattern = false
    private var lensDistortion = 0.0f
    private var distortionShader: RuntimeShader? = null
    private var currentUri: Uri? = null
    private lateinit var seekBar: SeekBar
    private lateinit var timeLabel: TextView
    private val uiHandler = Handler(Looper.getMainLooper())
    private var draggingSeek = false
    private val progressUpdater = object : Runnable {
        override fun run() {
            val player = leftPlayer
            syncRight()
            if (player != null && !draggingSeek && player.duration > 0) {
                seekBar.progress = ((player.currentPosition * 1000L) / player.duration).toInt().coerceIn(0, 1000)
                timeLabel.text = "${formatTime(player.currentPosition)} / ${formatTime(player.duration)}"
            }
            uiHandler.postDelayed(this, 500)
        }
    }

    private val prefs by lazy { getSharedPreferences("vrvision", MODE_PRIVATE) }

    private val pickVideo = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            try { contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION) } catch (_: Exception) {}
            loadVideo(uri)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        loadSettings()
        buildUi()
        applyLayoutMode()
        applyLensDistortion()
        immersive()
        uiHandler.post(progressUpdater)
        scheduleControlsHide()
    }

    private fun immersive() {
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_LAYOUT_STABLE)
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.BLACK)
            setPadding(0, 0, 0, 0)
        }
        controlsPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(0xEE101016.toInt())
            setPadding(10, 6, 10, 6)
        }
        val header = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        header.addView(TextView(this).apply { text = "VR VISION"; textSize = 20f; setTextColor(Color.WHITE) },
            LinearLayout.LayoutParams(0, -2, 1f))
        status = TextView(this).apply { text = "Выбери видео"; textSize = 12f; setTextColor(0xFFB8B8C4.toInt()) }
        header.addView(status)
        controlsPanel.addView(header)

        val timeline = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        timeLabel = TextView(this).apply { text = "00:00 / 00:00"; textSize = 10f; setTextColor(Color.WHITE) }
        timeline.addView(timeLabel)
        seekBar = SeekBar(this).apply {
            max = 1000
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar?, value: Int, fromUser: Boolean) {
                    if (fromUser) {
                        showControls()
                        val duration = leftPlayer?.duration ?: 0L
                        if (duration > 0) timeLabel.text = "${formatTime(duration * value / 1000)} / ${formatTime(duration)}"
                    }
                }
                override fun onStartTrackingTouch(bar: SeekBar?) { draggingSeek = true; showControls() }
                override fun onStopTrackingTouch(bar: SeekBar?) {
                    val duration = leftPlayer?.duration ?: 0L
                    if (duration > 0) {
                        val target = duration * (bar?.progress ?: 0) / 1000
                        leftPlayer?.seekTo(target)
                        rightPlayer?.seekTo(target)
                    }
                    draggingSeek = false
                    scheduleControlsHide()
                }
            })
        }
        timeline.addView(seekBar, LinearLayout.LayoutParams(0, -2, 1f))
        controlsPanel.addView(timeline)

        val volumeRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER_VERTICAL }
        volumeRow.addView(TextView(this).apply { text = "Громкость"; textSize = 10f; setTextColor(Color.WHITE) })
        volumeRow.addView(SeekBar(this).apply {
            max = 100
            progress = prefs.getInt("volume", 100)
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(bar: SeekBar?, value: Int, fromUser: Boolean) {
                    leftPlayer?.volume = value / 100f
                    prefs.edit().putInt("volume", value).apply()
                    if (fromUser) showControls()
                }
                override fun onStartTrackingTouch(bar: SeekBar?) { showControls() }
                override fun onStopTrackingTouch(bar: SeekBar?) { scheduleControlsHide() }
            })
        }, LinearLayout.LayoutParams(0, -2, 1f))
        controlsPanel.addView(volumeRow)

        val row1 = LinearLayout(this).apply { gravity = Gravity.CENTER; orientation = LinearLayout.HORIZONTAL }
        row1.addView(makeButton("Открыть файл") { pickVideo.launch(arrayOf("video/*")) })
        row1.addView(makeButton("Ссылка") { askForUrl() })
        modeButton = makeButton("Mono") { sbs = !sbs; updateMode() }
        row1.addView(modeButton)
        row1.addView(makeButton("▶ / ⏸") { togglePlayback() })
        controlsPanel.addView(row1)

        val row2 = LinearLayout(this).apply { gravity = Gravity.CENTER; orientation = LinearLayout.HORIZONTAL }
        maskButton = makeButton("Маска: выкл.") { cycleMask() }
        row2.addView(maskButton)
        row2.addView(makeButton("Сетка") { grid = !grid; overlay.invalidate(); saveSettings() })
        row2.addView(makeButton("Настройки") { showSettings() })
        row2.addView(makeButton("Профили") { showProfiles() })
        controlsPanel.addView(row2)
        val row3 = LinearLayout(this).apply { gravity = Gravity.CENTER; orientation = LinearLayout.HORIZONTAL }
        row3.addView(makeButton("Калибровка") { showCalibration() })
        controlsPanel.addView(row3)

        stage = FrameLayout(this).apply {
            setBackgroundColor(Color.BLACK)
            layoutParams = LinearLayout.LayoutParams(-1, 0, 1f)
            setOnClickListener { showControls() }
            isClickable = true
        }
        val eyes = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        leftView = makePlayerView().apply { setOnClickListener { showControls() } }
        rightView = makePlayerView().apply { setOnClickListener { showControls() } }
        eyes.addView(leftView, LinearLayout.LayoutParams(0, -1, 1f))
        eyes.addView(rightView, LinearLayout.LayoutParams(0, -1, 1f))
        stage.addView(eyes, FrameLayout.LayoutParams(-1, -1))
        overlay = CalibrationOverlay()
        overlay.isClickable = false
        stage.addView(overlay, FrameLayout.LayoutParams(-1, -1))
        root.addView(controlsPanel, LinearLayout.LayoutParams(-1, -2))
        root.addView(stage)
        setContentView(root)
    }

    private fun scheduleControlsHide() {
        uiHandler.removeCallbacks(hideControlsTask)
        if (controlsVisible) uiHandler.postDelayed(hideControlsTask, 5000)
    }

    private fun hideControls() {
        if (!controlsVisible || isFinishing) return
        controlsVisible = false
        controlsPanel.visibility = View.GONE
    }

    private fun showControls() {
        controlsVisible = true
        controlsPanel.visibility = View.VISIBLE
        scheduleControlsHide()
    }

    private fun formatTime(ms: Long): String {
        if (ms < 0 || ms == androidx.media3.common.C.TIME_UNSET) return "--:--"
        val total = ms / 1000
        return "%02d:%02d".format(total / 60, total % 60)
    }

    private fun makePlayerView(): PlayerView =
        (layoutInflater.inflate(R.layout.vr_player_view, null, false) as PlayerView).apply {
            useController = false
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
            setBackgroundColor(Color.BLACK)
        }

    private fun makeButton(label: String, action: () -> Unit) = Button(this).apply {
        text = label
        textSize = 10f
        isAllCaps = false
        setOnClickListener { showControls(); action() }
    }

    private fun ensurePlayers() {
        if (leftPlayer != null) return
        leftPlayer = ExoPlayer.Builder(this).build().also { leftView.player = it }
        rightPlayer = ExoPlayer.Builder(this).build().also { it.volume = 0f; rightView.player = it }
        leftPlayer?.addListener(object : Player.Listener {
            override fun onPlayerError(error: PlaybackException) {
                status.text = "Ошибка видео: ${error.errorCodeName}"
            }
            override fun onPlaybackStateChanged(playbackState: Int) {
                status.text = when (playbackState) {
                    Player.STATE_BUFFERING -> "Загрузка…"
                    Player.STATE_READY -> "Видео готово"
                    Player.STATE_ENDED -> "Конец видео"
                    else -> "VR Vision"
                }
                syncRight()
            }
        })
    }

    private fun loadVideo(uri: Uri) {
        currentUri = uri
        ensurePlayers()
        val item = MediaItem.fromUri(uri)
        leftPlayer?.setMediaItem(item)
        rightPlayer?.setMediaItem(item)
        leftPlayer?.prepare()
        rightPlayer?.prepare()
        leftPlayer?.playWhenReady = true
        rightPlayer?.playWhenReady = true
        status.text = "Видео открыто"
    }

    private fun askForUrl() {
        val input = EditText(this).apply { hint = "https://example.com/video.mp4"; setSingleLine(true) }
        AlertDialog.Builder(this).setTitle("Открыть видео по ссылке").setView(input)
            .setNegativeButton("Отмена", null)
            .setPositiveButton("Открыть") { _, _ ->
                val raw = input.text.toString().trim()
                if (raw.startsWith("https://")) loadVideo(Uri.parse(raw))
                else Toast.makeText(this, "Нужна прямая HTTPS-ссылка на видеофайл, не страница YouTube", Toast.LENGTH_LONG).show()
            }.show()
    }

    private fun togglePlayback() {
        val p = leftPlayer ?: run { Toast.makeText(this, "Сначала открой видео", Toast.LENGTH_SHORT).show(); return }
        if (p.isPlaying) { p.pause(); rightPlayer?.pause() }
        else { p.play(); rightPlayer?.play() }
    }

    private fun syncRight() {
        val l = leftPlayer ?: return
        val r = rightPlayer ?: return
        if (kotlin.math.abs(l.currentPosition - r.currentPosition) > 120) r.seekTo(l.currentPosition)
        r.playWhenReady = l.playWhenReady
    }

    private fun updateMode() {
        modeButton.text = if (sbs) "SBS" else "Mono"
        applyLayoutMode()
        status.text = if (sbs) "Стерео: исходное SBS" else "Моно: два одинаковых изображения"
        saveSettings()
    }

    private fun applyLayoutMode() {
        leftView.post {
            val w = leftView.width.toFloat().coerceAtLeast(1f)
            if (sbs) {
                leftView.scaleX = 2f * zoom
                rightView.scaleX = 2f * zoom
                leftView.translationX = w * 0.5f + eyeOffset + leftEyeX
                rightView.translationX = -w * 0.5f - eyeOffset + rightEyeX
            } else {
                leftView.scaleX = zoom
                rightView.scaleX = zoom
                leftView.translationX = eyeOffset + leftEyeX
                rightView.translationX = -eyeOffset + rightEyeX
            }
            leftView.translationY = leftEyeY
            rightView.translationY = rightEyeY
            leftView.scaleY = zoom * leftEyeScale
            rightView.scaleY = zoom * rightEyeScale
            if (sbs) {
                leftView.scaleX = 2f * zoom * leftEyeScale
                rightView.scaleX = 2f * zoom * rightEyeScale
            } else {
                leftView.scaleX = zoom * leftEyeScale
                rightView.scaleX = zoom * rightEyeScale
            }
            overlay.invalidate()
        }
    }

    @SuppressLint("NewApi")
    private fun applyLensDistortion() {
        if (Build.VERSION.SDK_INT < 33) return
        val source = """
            uniform shader content;
            uniform float2 resolution;
            uniform float strength;
            half4 main(float2 coord) {
                float2 uv = coord / resolution;
                float2 p = (uv - float2(0.5, 0.5)) * 2.0;
                float r2 = dot(p, p);
                float2 warped = float2(0.5, 0.5) + p * (1.0 + strength * r2) * 0.5;
                if (warped.x < 0.0 || warped.x > 1.0 || warped.y < 0.0 || warped.y > 1.0) {
                    return half4(0.0, 0.0, 0.0, 1.0);
                }
                return content.eval(warped * resolution);
            }
        """.trimIndent()
        try {
            fun apply(view: PlayerView) {
                val surface = view.videoSurfaceView
                if (surface != null && surface.width > 0 && surface.height > 0) {
                    val shader = RuntimeShader(source)
                    shader.setFloatUniform("resolution", surface.width.toFloat(), surface.height.toFloat())
                    shader.setFloatUniform("strength", lensDistortion)
                    surface.setRenderEffect(RenderEffect.createRuntimeShaderEffect(shader, "content"))
                } else {
                    view.post { apply(view) }
                }
            }
            apply(leftView)
            apply(rightView)
        } catch (_: Exception) {
            Toast.makeText(this, "Не удалось применить коррекцию линз", Toast.LENGTH_SHORT).show()
        }
    }

    private fun cycleMask() {
        mask = (mask + 1) % 4
        maskButton.text = listOf("Маска: выкл.", "Маска: круг", "Маска: овал", "Маска: прямоуг.")[mask]
        overlay.invalidate()
        saveSettings()
    }

    private fun showSettings() {
        val panel = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(28, 8, 28, 8) }
        fun addSlider(label: String, initial: Int, max: Int, onChange: (Int) -> Unit) {
            panel.addView(TextView(this).apply { text = label; setTextColor(Color.WHITE) })
            panel.addView(SeekBar(this).apply { this.max = max; progress = initial; setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(s: SeekBar?, value: Int, fromUser: Boolean) { if (fromUser) onChange(value) }
                override fun onStartTrackingTouch(s: SeekBar?) {}
                override fun onStopTrackingTouch(s: SeekBar?) {}
            }) })
        }
        addSlider("Масштаб", ((zoom - 0.7f) * 100).toInt().coerceIn(0, 100), 100) { zoom = 0.7f + it / 100f; applyLayoutMode(); saveSettings() }
        addSlider("Общее разделение глаз", ((eyeOffset + 100) * 1.5f).toInt().coerceIn(0, 300), 300) { eyeOffset = it / 1.5f - 100f; applyLayoutMode(); saveSettings() }
        addSlider("Левый глаз: влево / вправо", ((leftEyeX + 120f) / 240f * 100f).toInt().coerceIn(0, 100), 100) { leftEyeX = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        addSlider("Правый глаз: влево / вправо", ((rightEyeX + 120f) / 240f * 100f).toInt().coerceIn(0, 100), 100) { rightEyeX = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        addSlider("Левый глаз: вверх / вниз", ((leftEyeY + 120f) / 240f * 100f).toInt().coerceIn(0, 100), 100) { leftEyeY = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        addSlider("Правый глаз: вверх / вниз", ((rightEyeY + 120f) / 240f * 100f).toInt().coerceIn(0, 100), 100) { rightEyeY = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        addSlider("Масштаб левого глаза", ((leftEyeScale - 0.7f) * 100f / 0.6f).toInt().coerceIn(0, 100), 100) { leftEyeScale = 0.7f + it / 100f * 0.6f; applyLayoutMode(); saveSettings() }
        addSlider("Масштаб правого глаза", ((rightEyeScale - 0.7f) * 100f / 0.6f).toInt().coerceIn(0, 100), 100) { rightEyeScale = 0.7f + it / 100f * 0.6f; applyLayoutMode(); saveSettings() }
        addSlider("Коррекция линз", ((lensDistortion + 0.35f) * 100f / 0.7f).toInt().coerceIn(0, 100), 100) {
            lensDistortion = it / 100f * 0.7f - 0.35f
            applyLensDistortion()
            saveSettings()
        }
        AlertDialog.Builder(this).setTitle("Настройки изображения").setView(ScrollView(this).apply { addView(panel) }).setPositiveButton("Готово", null).show()
    }

    private fun showCalibration() {
        val previousGrid = grid
        val previousPattern = calibrationPattern
        grid = true; calibrationPattern = true; overlay.invalidate()
        val panel = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(24, 8, 24, 8) }
        panel.addView(TextView(this).apply { text = "Надень очки. Настраивай левую и правую половины отдельно. Совмещай крестик с центром обзора, затем проверь мелкий текст и линии."; setTextColor(Color.WHITE); textSize = 14f; setPadding(0,0,0,12) })
        fun slider(label: String, initial: Int, max: Int, change: (Int) -> Unit) {
            panel.addView(TextView(this).apply { text = label; setTextColor(Color.WHITE); textSize = 13f })
            panel.addView(SeekBar(this).apply { this.max = max; progress = initial
                setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                    override fun onProgressChanged(bar: SeekBar?, value: Int, fromUser: Boolean) { if (fromUser) change(value) }
                    override fun onStartTrackingTouch(bar: SeekBar?) {}
                    override fun onStopTrackingTouch(bar: SeekBar?) {}
                })
            })
        }
        slider("Левый глаз: влево / вправо", ((leftEyeX + 120f) / 240f * 100).toInt().coerceIn(0,100),100) { leftEyeX = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        slider("Левый глаз: вверх / вниз", ((leftEyeY + 120f) / 240f * 100).toInt().coerceIn(0,100),100) { leftEyeY = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        slider("Левый глаз: масштаб", ((leftEyeScale - .7f) / .6f * 100).toInt().coerceIn(0,100),100) { leftEyeScale = .7f + it / 100f * .6f; applyLayoutMode(); saveSettings() }
        slider("Правый глаз: влево / вправо", ((rightEyeX + 120f) / 240f * 100).toInt().coerceIn(0,100),100) { rightEyeX = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        slider("Правый глаз: вверх / вниз", ((rightEyeY + 120f) / 240f * 100).toInt().coerceIn(0,100),100) { rightEyeY = it / 100f * 240f - 120f; applyLayoutMode(); saveSettings() }
        slider("Правый глаз: масштаб", ((rightEyeScale - .7f) / .6f * 100).toInt().coerceIn(0,100),100) { rightEyeScale = .7f + it / 100f * .6f; applyLayoutMode(); saveSettings() }
        slider("Расстояние между изображениями", ((eyeOffset + 100f) / 200f * 100).toInt().coerceIn(0,100),100) { eyeOffset = it / 100f * 200f - 100f; applyLayoutMode(); saveSettings() }
        val dialog = AlertDialog.Builder(this).setTitle("Калибровка Tecno + Shinecon")
            .setView(ScrollView(this).apply { addView(panel) })
            .setNeutralButton("Автоподгонка") { _, _ ->
                zoom = 1f; eyeOffset = 0f; leftEyeX = 0f; rightEyeX = 0f; leftEyeY = 0f; rightEyeY = 0f
                leftEyeScale = 1f; rightEyeScale = 1f; lensDistortion = 0f
                applyLayoutMode(); applyLensDistortion(); saveSettings()
                Toast.makeText(this, "Начальная центровка установлена — при необходимости доведи вручную.", Toast.LENGTH_LONG).show()
            }
            .setPositiveButton("Готово", null)
            .setOnDismissListener { grid = previousGrid; calibrationPattern = previousPattern; overlay.invalidate(); saveSettings() }
            .create()
        dialog.show()
    }

    private fun showProfiles() {
        val actions = arrayOf("Сохранить новый профиль", "Загрузить профиль", "Удалить профиль", "Сбросить настройки", "Профиль Tecno Pova 6 Pro + Shinecon")
        AlertDialog.Builder(this).setTitle("Профили VR-очков").setItems(actions) { _, which ->
            when (which) {
                0 -> {
                    val input = EditText(this).apply { hint = "Например: Google Cardboard" }
                    AlertDialog.Builder(this).setTitle("Название профиля").setView(input)
                        .setNegativeButton("Отмена", null)
                        .setPositiveButton("Сохранить") { _, _ ->
                            val name = input.text.toString().trim()
                            if (name.isBlank()) {
                                Toast.makeText(this, "Введи название профиля", Toast.LENGTH_SHORT).show()
                            } else {
                                val key = "profile_" + name
                                prefs.edit().putBoolean(key + "_sbs", sbs).putBoolean(key + "_grid", grid)
                                    .putInt(key + "_mask", mask).putFloat(key + "_zoom", zoom)
                                    .putFloat(key + "_offset", eyeOffset).putFloat(key + "_left_x", leftEyeX).putFloat(key + "_right_x", rightEyeX)
                                    .putFloat(key + "_left_y", leftEyeY).putFloat(key + "_right_y", rightEyeY)
                                    .putFloat(key + "_left_scale", leftEyeScale).putFloat(key + "_right_scale", rightEyeScale)
                                    .putFloat(key + "_distortion", lensDistortion).putStringSet("profile_names",
                                        (prefs.getStringSet("profile_names", emptySet()) ?: emptySet()) + name).apply()
                                Toast.makeText(this, "Профиль «$name» сохранён", Toast.LENGTH_SHORT).show()
                            }
                        }.show()
                }
                1, 2 -> {
                    val names = (prefs.getStringSet("profile_names", emptySet()) ?: emptySet()).toList().sorted()
                    if (names.isEmpty()) {
                        Toast.makeText(this, "Сначала сохрани профиль", Toast.LENGTH_SHORT).show()
                    } else {
                        AlertDialog.Builder(this).setTitle(if (which == 1) "Выбери профиль" else "Удалить профиль")
                            .setItems(names.toTypedArray()) { _, index ->
                                val name = names[index]
                                val key = "profile_" + name
                                if (which == 1) {
                                    sbs = prefs.getBoolean(key + "_sbs", false)
                                    grid = prefs.getBoolean(key + "_grid", false)
                                    mask = prefs.getInt(key + "_mask", 0)
                                    zoom = prefs.getFloat(key + "_zoom", 1f)
                                    eyeOffset = prefs.getFloat(key + "_offset", 0f)
                                    leftEyeX = prefs.getFloat(key + "_left_x", 0f)
                                    rightEyeX = prefs.getFloat(key + "_right_x", 0f)
                                    leftEyeY = prefs.getFloat(key + "_left_y", 0f)
                                    rightEyeY = prefs.getFloat(key + "_right_y", 0f)
                                    leftEyeScale = prefs.getFloat(key + "_left_scale", 1f)
                                    rightEyeScale = prefs.getFloat(key + "_right_scale", 1f)
                                    lensDistortion = prefs.getFloat(key + "_distortion", 0f)
                                    updateMode()
                                    cycleMaskReset()
                                    overlay.invalidate()
                                    applyLayoutMode()
                                    applyLensDistortion()
                                    Toast.makeText(this, "Загружен профиль «$name»", Toast.LENGTH_SHORT).show()
                                } else {
                                    prefs.edit().remove(key + "_sbs").remove(key + "_grid").remove(key + "_mask")
                                        .remove(key + "_zoom").remove(key + "_offset").remove(key + "_left_x").remove(key + "_right_x")
                                        .remove(key + "_left_y").remove(key + "_right_y").remove(key + "_left_scale").remove(key + "_right_scale").remove(key + "_distortion")
                                        .putStringSet("profile_names", names.filter { it != name }.toSet()).apply()
                                    Toast.makeText(this, "Профиль удалён", Toast.LENGTH_SHORT).show()
                                }
                            }.show()
                    }
                }
                3 -> {
                    sbs = false; zoom = 1f; eyeOffset = 0f; leftEyeX = 0f; rightEyeX = 0f; leftEyeY = 0f; rightEyeY = 0f; leftEyeScale = 1f; rightEyeScale = 1f; lensDistortion = 0f; mask = 0; grid = false
                    updateMode(); cycleMaskReset(); applyLayoutMode(); applyLensDistortion(); saveSettings()
                }
                4 -> {
                    sbs = false
                    zoom = 1f
                    eyeOffset = 0f
                    leftEyeX = 0f; rightEyeX = 0f; leftEyeY = 0f; rightEyeY = 0f
                    leftEyeScale = 1f; rightEyeScale = 1f
                    lensDistortion = 0f
                    mask = 0
                    grid = false
                    updateMode(); cycleMaskReset(); applyLayoutMode(); applyLensDistortion(); saveSettings()
                    status.text = "Профиль Tecno + Shinecon загружен — настрой линзы регуляторами очков"
                    Toast.makeText(this, "Базовый профиль применён. Точную центровку выполни в настройках изображения.", Toast.LENGTH_LONG).show()
                }
            }
        }.show()
    }

    private fun cycleMaskReset() {
        maskButton.text = listOf("Маска: выкл.", "Маска: круг", "Маска: овал", "Маска: прямоуг.")[mask]
        overlay.invalidate()
    }

    private fun saveSettings() {
        prefs.edit().putBoolean("sbs", sbs).putBoolean("grid", grid).putInt("mask", mask)
            .putFloat("zoom", zoom).putFloat("offset", eyeOffset).putFloat("left_x", leftEyeX).putFloat("right_x", rightEyeX)
            .putFloat("left_y", leftEyeY).putFloat("right_y", rightEyeY).putFloat("left_scale", leftEyeScale)
            .putFloat("right_scale", rightEyeScale).putFloat("distortion", lensDistortion).apply()
    }

    private fun loadSettings() {
        sbs = prefs.getBoolean("sbs", false)
        grid = prefs.getBoolean("grid", false)
        mask = prefs.getInt("mask", 0)
        zoom = prefs.getFloat("zoom", 1f)
        eyeOffset = prefs.getFloat("offset", 0f)
        leftEyeX = prefs.getFloat("left_x", 0f)
        rightEyeX = prefs.getFloat("right_x", 0f)
        leftEyeY = prefs.getFloat("left_y", 0f)
        rightEyeY = prefs.getFloat("right_y", 0f)
        leftEyeScale = prefs.getFloat("left_scale", 1f)
        rightEyeScale = prefs.getFloat("right_scale", 1f)
        lensDistortion = prefs.getFloat("distortion", 0f)
    }

    inner class CalibrationOverlay : View(this) {
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val half = width / 2f
            if (mask != 0) {
                val path = Path().apply {
                    fillType = Path.FillType.EVEN_ODD
                    addRect(0f, 0f, width.toFloat(), height.toFloat(), Path.Direction.CW)
                    for (i in 0..1) {
                        val cx = half * (i + 0.5f)
                        val cy = height / 2f
                        val rx = half * 0.43f
                        val ry = height * 0.43f
                        when (mask) {
                            1 -> addCircle(cx, cy, min(rx, ry), Path.Direction.CW)
                            2 -> addOval(cx-rx, cy-ry, cx+rx, cy+ry, Path.Direction.CW)
                            3 -> addRoundRect(cx-rx, cy-ry, cx+rx, cy+ry, 24f, 24f, Path.Direction.CW)
                        }
                    }
                }
                paint.color = Color.BLACK
                canvas.drawPath(path, paint)
            }
            if (calibrationPattern) {
                for (i in 0..1) {
                    val cx = half * (i + 0.5f); val cy = height / 2f
                    paint.color = 0xFFFFD54F.toInt(); paint.strokeWidth = 2f; paint.style = Paint.Style.STROKE
                    canvas.drawCircle(cx, cy, min(half, height) * 0.16f, paint)
                    canvas.drawLine(cx - 34f, cy, cx + 34f, cy, paint)
                    canvas.drawLine(cx, cy - 34f, cx, cy + 34f, paint)
                    paint.color = Color.WHITE; paint.style = Paint.Style.FILL; paint.textSize = 22f
                    canvas.drawText(if (i == 0) "L" else "R", cx - 7f, cy - min(half, height) * 0.22f, paint)
                }
                paint.style = Paint.Style.FILL
            }
            if (grid) {
                paint.color = 0x8877FF77.toInt()
                paint.strokeWidth = 1f
                for (i in 1..9) {
                    val x = width * i / 10f
                    val y = height * i / 10f
                    canvas.drawLine(x, 0f, x, height.toFloat(), paint)
                    canvas.drawLine(0f, y, width.toFloat(), y, paint)
                }
                canvas.drawLine(half, 0f, half, height.toFloat(), paint)
            }
        }
    }

    override fun onResume() { super.onResume(); immersive() }
    override fun onStop() { super.onStop(); leftPlayer?.pause(); rightPlayer?.pause() }
    override fun onDestroy() {
        leftView.player = null
        rightView.player = null
        uiHandler.removeCallbacks(progressUpdater)
        uiHandler.removeCallbacks(hideControlsTask)
        leftPlayer?.release()
        rightPlayer?.release()
        leftPlayer = null
        rightPlayer = null
        super.onDestroy()
    }
}
