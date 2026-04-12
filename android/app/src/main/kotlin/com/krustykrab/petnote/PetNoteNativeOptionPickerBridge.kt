package com.krustykrab.petnote

import android.app.Activity
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import com.google.android.material.bottomsheet.BottomSheetDialog
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PetNoteNativeOptionPickerBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "petnote/native_option_picker"
    }

    private data class OptionItem(
        val value: String,
        val label: String,
    )

    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var pendingResult: MethodChannel.Result? = null
    private var pendingDialog: BottomSheetDialog? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.success(
                errorPayload(
                    errorCode = "invalidResponse",
                    message = "Another native option picker request is already running.",
                ),
            )
            return
        }

        when (call.method) {
            "pickSingleOption" -> {
                val arguments = call.arguments as? Map<*, *>
                val title = arguments?.get("title") as? String
                val selectedValue = arguments?.get("selectedValue") as? String
                val options = parseOptions(arguments?.get("options"))
                if (title.isNullOrBlank() || options.isEmpty()) {
                    result.success(
                        errorPayload(
                            errorCode = "invalidResponse",
                            message = "Missing title or options for native option picker.",
                        ),
                    )
                    return
                }
                presentOptionPicker(
                    title = title,
                    selectedValue = selectedValue,
                    options = options,
                    result = result,
                )
            }

            else -> result.notImplemented()
        }
    }

    private fun presentOptionPicker(
        title: String,
        selectedValue: String?,
        options: List<OptionItem>,
        result: MethodChannel.Result,
    ) {
        val dialog = BottomSheetDialog(activity)
        val selectedIndex = options.indexOfFirst { it.value == selectedValue }
        val titleView = TextView(activity).apply {
            text = title
            setPadding(dp(24), dp(20), dp(24), dp(12))
            textSize = 18f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
        }
        val listView = ListView(activity).apply {
            choiceMode = ListView.CHOICE_MODE_SINGLE
            dividerHeight = 0
            adapter = ArrayAdapter(
                activity,
                android.R.layout.simple_list_item_single_choice,
                options.map { it.label },
            )
            setOnItemClickListener { _, _, position, _ ->
                finish(successPayload(options[position].value))
            }
        }
        if (selectedIndex >= 0) {
            listView.setItemChecked(selectedIndex, true)
        }
        val container = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            addView(titleView)
            addView(listView)
        }

        dialog.setContentView(container)
        dialog.setOnDismissListener {
            if (pendingResult != null) {
                finish(cancelledPayload())
            }
        }
        pendingDialog = dialog
        pendingResult = result
        dialog.show()
    }

    private fun finish(payload: Map<String, Any?>) {
        val callback = pendingResult ?: return
        val dialog = pendingDialog
        pendingResult = null
        pendingDialog = null
        dialog?.setOnDismissListener(null)
        if (dialog?.isShowing == true) {
            dialog.dismiss()
        }
        callback.success(payload)
    }

    private fun parseOptions(raw: Any?): List<OptionItem> {
        val options = raw as? List<*> ?: return emptyList()
        return options.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val value = map["value"] as? String ?: return@mapNotNull null
            val label = map["label"] as? String ?: return@mapNotNull null
            if (value.isBlank() || label.isBlank()) {
                return@mapNotNull null
            }
            OptionItem(value = value, label = label)
        }
    }

    private fun dp(value: Int): Int {
        val density = activity.resources.displayMetrics.density
        return (value * density).toInt()
    }

    private fun successPayload(selectedValue: String): Map<String, Any?> {
        return mapOf(
            "status" to "success",
            "selectedValue" to selectedValue,
        )
    }

    private fun cancelledPayload(): Map<String, Any?> {
        return mapOf(
            "status" to "cancelled",
            "errorCode" to "cancelled",
        )
    }

    private fun errorPayload(
        errorCode: String,
        message: String,
    ): Map<String, Any?> {
        return mapOf(
            "status" to "error",
            "errorCode" to errorCode,
            "errorMessage" to message,
        )
    }
}
