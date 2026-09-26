package com.vnaddress.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import com.vnaddress.widget.core.VnaddrCore

/**
 * Placeholder Glance widget (phase0/03 scope: proves the widget module
 * builds and links the shared core, per ADR 0002 §7's "both widgets link
 * the core from phase0/03 onward"). Real content — reading
 * `widget/last_result.json` (M2a) or a live lookup (M2b) — is phase2/01.
 */
class GreetingWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            WidgetContent()
        }
    }
}

@Composable
private fun WidgetContent() {
    val corePing = runCatching {
        VnaddrCore.checkAbiOrThrow()
        VnaddrCore.ping()
    }.getOrNull()

    Column(modifier = androidx.glance.GlanceModifier.fillMaxSize().padding(12.dp)) {
        Text("VN Address Widget")
        Text(
            if (corePing != null) "core linked (ping=$corePing)" else "core not linked",
        )
    }
}

class GreetingWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = GreetingWidget()
}
