package org.bunnypad.android

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.Image
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.charasoft.bunnypad.R
import org.bunnypad.android.theme.BunnyPadTheme

class MainActivity : ComponentActivity() {
    private val editor: EditorModel by viewModels()
    private val appUpdateManager by lazy { com.google.android.play.core.appupdate.AppUpdateManagerFactory.create(this) }
    private val updateLauncher = registerForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.StartIntentSenderForResult()
    ) { result ->
        if (result.resultCode != RESULT_OK) {
            // Update flow canceled or failed
        }
    }

    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        handleIntent(intent)
        setContent {
            var showSettings by remember { mutableStateOf(false) }
            var showAbout by remember { mutableStateOf(false) }
            var showUpdatePrompt by remember { mutableStateOf(false) }
            var updateInfoToStart by remember { mutableStateOf<com.google.android.play.core.appupdate.AppUpdateInfo?>(null) }

            LaunchedEffect(Unit) {
                appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
                    if (info.updateAvailability() == com.google.android.play.core.install.model.UpdateAvailability.UPDATE_AVAILABLE &&
                        info.isUpdateTypeAllowed(com.google.android.play.core.install.model.AppUpdateType.IMMEDIATE)) {
                        updateInfoToStart = info
                        showUpdatePrompt = true
                    }
                }
            }

            if (editor.isHome) {
                HomeScreen(
                    model = editor,
                    onSettings = { showSettings = true },
                    onAbout = { showAbout = true }
                )
            } else {
                EditorScreen(editor)
            }

            if (showUpdatePrompt && updateInfoToStart != null) {
                val dark = when (editor.appearance) { 1 -> false; 2 -> true; else -> isSystemInDarkTheme() }
                BunnyPadTheme(darkTheme = dark, dynamicColor = false) {
                    val sheetState = rememberModalBottomSheetState()
                    ModalBottomSheet(
                        onDismissRequest = { showUpdatePrompt = false },
                        sheetState = sheetState
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp)
                                .verticalScroll(rememberScrollState())
                        ) {
                            Text("App Update Available", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(12.dp))
                            Text("A new version of BunnyPad is available with inline install support. Update now to enjoy the latest features!", style = MaterialTheme.typography.bodyMedium)
                            Spacer(modifier = Modifier.height(24.dp))
                            Button(
                                onClick = {
                                    showUpdatePrompt = false
                                    updateInfoToStart?.let { info ->
                                        appUpdateManager.startUpdateFlowForResult(
                                            info,
                                            updateLauncher,
                                            com.google.android.play.core.appupdate.AppUpdateOptions.newBuilder(com.google.android.play.core.install.model.AppUpdateType.IMMEDIATE).build()
                                        )
                                    }
                                },
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text("Update Now (Inline Install)")
                            }
                            Spacer(modifier = Modifier.height(36.dp))
                        }
                    }
                }
            }

            if (showSettings) {
                val dark = when (editor.appearance) { 1 -> false; 2 -> true; else -> isSystemInDarkTheme() }
                BunnyPadTheme(darkTheme = dark, dynamicColor = false) {
                    val sheetState = rememberModalBottomSheetState()
                    ModalBottomSheet(
                        onDismissRequest = { showSettings = false },
                        sheetState = sheetState
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp)
                                .verticalScroll(rememberScrollState())
                        ) {
                            Text("Editor settings", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(16.dp))

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Checkbox(editor.wrap, { editor.wrap = it; editor.savePreferences() })
                                Text("Word wrap", Modifier.padding(start = 8.dp))
                            }

                            Spacer(modifier = Modifier.height(12.dp))

                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Checkbox(editor.showQuickNoteTile, { editor.showQuickNoteTile = it; editor.savePreferences() })
                                Text("Enable Quick Settings Tile", Modifier.padding(start = 8.dp))
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Text size: ${editor.fontSize} sp")
                            Slider(editor.fontSize.toFloat(), { editor.fontSize = it.toInt(); editor.savePreferences() }, valueRange = 12f..32f, steps = 19)

                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Font Family")
                            listOf("Monospace", "Sans-Serif", "Serif").forEachIndexed { index, title ->
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    RadioButton(editor.fontChoice == index, { editor.fontChoice = index; editor.savePreferences() })
                                    Text(title, Modifier.padding(start = 8.dp))
                                }
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                            Text("Appearance")
                            listOf("System theme", "Light", "Dark").forEachIndexed { index, title ->
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    RadioButton(editor.appearance == index, { editor.appearance = index; editor.savePreferences() })
                                    Text(title, Modifier.padding(start = 8.dp))
                                }
                            }

                            Spacer(modifier = Modifier.height(36.dp))
                        }
                    }
                }
            }

            if (showAbout) {
                val dark = when (editor.appearance) { 1 -> false; 2 -> true; else -> isSystemInDarkTheme() }
                BunnyPadTheme(darkTheme = dark, dynamicColor = false) {
                    val sheetState = rememberModalBottomSheetState()
                    ModalBottomSheet(
                        onDismissRequest = { showAbout = false },
                        sheetState = sheetState
                    ) {
                        val context = LocalContext.current
                        val versionName = remember {
                            runCatching {
                                context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "1.0"
                            }.getOrDefault("1.0")
                        }
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(24.dp)
                                .verticalScroll(rememberScrollState())
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text("About BunnyPad", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                                    Spacer(modifier = Modifier.height(2.dp))
                                    Text("Version $versionName", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.primary)
                                }
                                Image(
                                    painter = painterResource(id = R.drawable.about_logo),
                                    contentDescription = "App Logo",
                                    modifier = Modifier.size(56.dp)
                                )
                            }
                            Spacer(modifier = Modifier.height(16.dp))

                            Text("BunnyPad: The Newest and Cutest Way to take notes!\n\nNative Android port. Original BunnyPad by GSYT Productions.\n\nContributors & Credits:\n• PBbunnypower (Icon & Dedicated To)\n• GarryStraitYT (Main Developer)\n• BunnyFndr (Co-developer)\n• ZeRoTeCh00\n• Unity Pixelheart\n• ByPad\n• i486girl & K4sum1\n• Wolfieboy09\n• teknixstuff\n• Aoterno Technologies / Sneksoft (Mac & iOS / Android ports)\n\nApache License 2.0.")

                            Spacer(modifier = Modifier.height(16.dp))
                            val uriHandler = androidx.compose.ui.platform.LocalUriHandler.current
                            TextButton(onClick = { uriHandler.openUri("https://github.com/GSYT-Productions/BunnyPad-SRC") }) {
                                Text("Original source & license")
                            }

                            Spacer(modifier = Modifier.height(36.dp))
                        }
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.action == "org.bunnypad.ACTION_QUICK_NOTE") {
            editor.quickNote()
        }
    }

    override fun onPause() {
        editor.flushDraft()
        super.onPause()
    }

    override fun onStop() {
        editor.flushDraft()
        super.onStop()
    }
}
