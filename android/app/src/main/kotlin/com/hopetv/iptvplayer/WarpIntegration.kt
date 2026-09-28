package com.hopetv.iptvplayer

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

internal class WarpIntegration(private val context: Context) {
    companion object {
        private const val CHANNEL = "hope_iptv/warp"
        private const val CLOUDFLARE_PACKAGE =
            "com.cloudflare.onedotonedotonedotone"
        private const val PLAY_STORE_URL =
            "https://play.google.com/store/apps/details?id=$CLOUDFLARE_PACKAGE"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val integration = WarpIntegration(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "isInstalled" -> result.success(integration.isInstalled())
                        "openWarp" -> result.success(integration.openWarp())
                        "openStore" -> {
                            integration.openStore()
                            result.success(null)
                        }
                        "getVpnState" -> result.success(integration.isVpnActive())
                        else -> result.notImplemented()
                    }
                }
        }
    }

    private fun isInstalled(): Boolean = try {
        context.packageManager.getPackageInfo(CLOUDFLARE_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun openWarp(): Boolean {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(CLOUDFLARE_PACKAGE)
            ?: return false
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            context.startActivity(launchIntent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun openStore() {
        val marketIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("market://details?id=$CLOUDFLARE_PACKAGE"),
        ).apply {
            setPackage("com.android.vending")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(marketIntent)
        } catch (_: ActivityNotFoundException) {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(PLAY_STORE_URL))
                .apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            context.startActivity(browserIntent)
        }
    }

    private fun isVpnActive(): Boolean {
        val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE)
            as ConnectivityManager
        val activeNetwork = manager.activeNetwork ?: return false
        return manager.getNetworkCapabilities(activeNetwork)
            ?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) == true
    }
}
