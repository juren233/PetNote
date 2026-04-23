package com.krustykrab.petnote

import android.content.Context
import android.view.MotionEvent
import android.view.View
import android.view.ViewParent
import android.view.ViewTreeObserver
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.util.fastCoerceIn
import com.kyant.shapes.Capsule
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.flow.collectLatest

class AndroidLiquidGlassToggleFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return AndroidLiquidGlassTogglePlatformView(
            context = context,
            messenger = messenger,
            viewId = viewId,
            args = args.asCreationParams(),
        )
    }
}

private fun Any?.asCreationParams(): Map<String, Any?> {
    return (this as? Map<*, *>)
        ?.mapNotNull { (key, value) ->
            (key as? String)?.let { it to value }
        }
        ?.toMap()
        .orEmpty()
}

private class AndroidLiquidGlassTogglePlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    args: Map<String, Any?>,
) : PlatformView {
    private val composeView = ComposeView(context)
    private val channel = MethodChannel(messenger, "petnote/android_liquid_glass_toggle_$viewId")
    private val firstLayoutListener =
        object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                if (hasReportedFirstLayout || composeView.width <= 0 || composeView.height <= 0) {
                    return
                }
                hasReportedFirstLayout = true
                if (composeView.viewTreeObserver.isAlive) {
                    composeView.viewTreeObserver.removeOnGlobalLayoutListener(this)
                }
                prewarmRequestToken += 1
            }
        }

    private var selected by mutableStateOf(args["selected"] as? Boolean ?: false)
    private var brightnessName by mutableStateOf(args["brightness"] as? String ?: "light")
    private var backdropColorArgb by mutableIntStateOf(
        (args["backdropColor"] as? Number)?.toInt() ?: 0xFFFFFFFF.toInt(),
    )
    private var prewarmRequestToken by mutableIntStateOf(0)
    private var hasReportedFirstLayout = false

    init {
        composeView.setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnDetachedFromWindow,
        )
        composeView.setOnTouchListener(::onComposeTouch)
        composeView.viewTreeObserver.addOnGlobalLayoutListener(firstLayoutListener)
        composeView.setContent {
            AndroidLiquidGlassToggle(
                selected = { selected },
                onSelect = { next ->
                    selected = next
                    channel.invokeMethod("selectedChanged", next)
                },
                brightnessName = brightnessName,
                backdropColor = Color(backdropColorArgb),
                prewarmRequestToken = prewarmRequestToken,
            )
        }
        channel.setMethodCallHandler(::onMethodCall)
    }

    override fun getView() = composeView

    override fun dispose() {
        if (composeView.viewTreeObserver.isAlive) {
            composeView.viewTreeObserver.removeOnGlobalLayoutListener(firstLayoutListener)
        }
        channel.setMethodCallHandler(null)
        composeView.disposeComposition()
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSelected" -> {
                selected = call.arguments == true
                result.success(null)
            }
            "setBrightness" -> {
                brightnessName = call.arguments as? String ?: brightnessName
                result.success(null)
            }
            "setBackdropColor" -> {
                backdropColorArgb = (call.arguments as? Number)?.toInt() ?: backdropColorArgb
                result.success(null)
            }
            "prewarmFirstInteraction" -> {
                prewarmRequestToken += 1
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun onComposeTouch(view: View, event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN,
            MotionEvent.ACTION_MOVE -> view.requestParentsDisallowInterceptTouchEvent(true)
            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_CANCEL -> view.requestParentsDisallowInterceptTouchEvent(false)
        }
        return false
    }
}

private fun View.requestParentsDisallowInterceptTouchEvent(disallow: Boolean) {
    var currentParent: ViewParent? = parent
    while (currentParent != null) {
        currentParent.requestDisallowInterceptTouchEvent(disallow)
        currentParent = currentParent.parent
    }
}

@Composable
fun AndroidLiquidGlassToggle(
    selected: () -> Boolean,
    onSelect: (Boolean) -> Unit,
    brightnessName: String,
    backdropColor: Color,
    prewarmRequestToken: Int = 0,
) {
    val isLightTheme = brightnessName != "dark"
    val accentColor =
        if (isLightTheme) Color(0xFF34C759)
        else Color(0xFF30D158)
    val trackColor =
        if (isLightTheme) Color(0xFF787878).copy(alpha = 0.2f)
        else Color(0xFF787880).copy(alpha = 0.36f)

    val density = LocalDensity.current
    val isLtr = LocalLayoutDirection.current == LayoutDirection.Ltr
    val dragWidth = with(density) { 20f.dp.toPx() }
    val animationScope = rememberCoroutineScope()
    var didDrag by remember { mutableStateOf(false) }
    var fraction by remember { mutableFloatStateOf(if (selected()) 1f else 0f) }
    lateinit var dampedDragAnimation: DampedDragAnimation
    dampedDragAnimation = remember(animationScope) {
        DampedDragAnimation(
            animationScope = animationScope,
            initialValue = fraction,
            valueRange = 0f..1f,
            visibilityThreshold = 0.001f,
            initialScale = 1f,
            pressedScale = 1.5f,
            onDragStarted = {},
            onDragStopped = {
                if (didDrag) {
                    fraction = if (targetValue >= 0.5f) 1f else 0f
                    onSelect(fraction == 1f)
                }
                didDrag = false
            },
            onDrag = { _, dragAmount ->
                if (!didDrag) {
                    didDrag = dragAmount.x != 0f
                }
                val delta = dragAmount.x / dragWidth
                val nextFraction =
                    if (isLtr) (fraction + delta).fastCoerceIn(0f, 1f)
                    else (fraction - delta).fastCoerceIn(0f, 1f)
                fraction = nextFraction
                dampedDragAnimation.updateValue(nextFraction)
            },
        )
    }
    val toggleSelection: () -> Unit = {
        val next = !selected()
        fraction = if (next) 1f else 0f
        dampedDragAnimation.updateValue(fraction)
        onSelect(next)
    }
    val tapModifier =
        Modifier.pointerInput(Unit) {
            detectTapGestures(
                onTap = {
                    toggleSelection()
                },
            )
        }
    LaunchedEffect(prewarmRequestToken) {
        if (prewarmRequestToken <= 0) {
            return@LaunchedEffect
        }
        dampedDragAnimation.prewarmReleaseCycle()
    }
    LaunchedEffect(selected) {
        snapshotFlow { selected() }
            .collectLatest { isSelected ->
                val target = if (isSelected) 1f else 0f
                if (target != fraction) {
                    fraction = target
                    dampedDragAnimation.updateValue(target)
                }
            }
    }

    Box(
        Modifier.size(96f.dp, 64f.dp),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            Modifier
                .size(72f.dp, 48f.dp)
                .semantics {
                    role = Role.Switch
                    toggleableState = if (selected()) ToggleableState.On else ToggleableState.Off
                    onClick {
                        toggleSelection()
                        true
                    }
                }
                .then(tapModifier)
                .then(dampedDragAnimation.modifier),
            contentAlignment = Alignment.Center,
        ) {
            Box(
                Modifier.size(64f.dp, 28f.dp),
                contentAlignment = Alignment.CenterStart,
            ) {
                Box(
                    Modifier
                        .clip(Capsule())
                        .drawBehind {
                            val progress = dampedDragAnimation.value
                            drawRect(lerp(trackColor, accentColor, progress))
                        }
                        .size(64f.dp, 28f.dp),
                )

                Box(
                    Modifier
                        .graphicsLayer {
                            val progress = dampedDragAnimation.value
                            val padding = 2f.dp.toPx()
                            translationX =
                                if (isLtr) androidx.compose.ui.util.lerp(padding, padding + dragWidth, progress)
                                else androidx.compose.ui.util.lerp(-padding, -(padding + dragWidth), progress)
                        }
                        .clip(Capsule())
                        .background(Color.White)
                        .size(40f.dp, 24f.dp),
                )
            }
        }
    }
}
