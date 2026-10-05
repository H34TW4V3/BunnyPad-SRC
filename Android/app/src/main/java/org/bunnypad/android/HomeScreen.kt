package org.bunnypad.android

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.charasoft.bunnypad.R
import org.bunnypad.android.theme.BunnyPadTheme

@Composable
fun HomeScreen(model: EditorModel, onSettings: () -> Unit, onAbout: () -> Unit) {
    val dark = when (model.appearance) { 1 -> false; 2 -> true; else -> isSystemInDarkTheme() }
    BunnyPadTheme(darkTheme = dark, dynamicColor = false) {
        val openLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            if (uri != null) model.open(uri)
        }

        val backgroundBrush = Brush.linearGradient(
            colors = listOf(Color(0xFF1A61AE), Color(0xFF7341BB), Color(0xFFC545B6))
        )
        val goldColor = Color(0xFFFFC43B)

        Box(modifier = Modifier.fillMaxSize().background(backgroundBrush)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .systemBarsPadding()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                // Logo
                Image(
                    painter = painterResource(id = R.drawable.about_logo),
                    contentDescription = "BunnyPad Logo",
                    modifier = Modifier
                        .size(150.dp)
                        .padding(bottom = 16.dp)
                )

                // Title & Subtitle
                Text(
                    text = "BunnyPad",
                    style = MaterialTheme.typography.headlineLarge.copy(fontSize = 38.sp, fontWeight = FontWeight.Bold),
                    color = Color.White
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = "The Newest and Cutest way to take notes",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color.White.copy(alpha = 0.85f)
                )

                Spacer(modifier = Modifier.height(36.dp))

                // Action Tiles (New Note & Open File)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    // New Note
                    Button(
                        onClick = { model.newDocument() },
                        modifier = Modifier.weight(1f).height(90.dp),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = goldColor)
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Default.Edit, contentDescription = null, tint = Color.Black)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("New Note", color = Color.Black, fontWeight = FontWeight.Bold)
                        }
                    }

                    // Open File
                    Button(
                        onClick = { openLauncher.launch(arrayOf("*/*")) },
                        modifier = Modifier.weight(1f).height(90.dp),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.White.copy(alpha = 0.18f))
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Icon(Icons.Default.Menu, contentDescription = null, tint = Color.White)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("Open File", color = Color.White, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // Recent Files Section
                Text(
                    text = "Recent Files",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp)
                )

                if (model.recentFiles.isEmpty()) {
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
                        color = Color.White.copy(alpha = 0.1f)
                    ) {
                        Text(
                            text = "No recent files yet",
                            style = MaterialTheme.typography.bodyMedium,
                            color = Color.White.copy(alpha = 0.7f),
                            modifier = Modifier.padding(18.dp)
                        )
                    }
                } else {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        model.recentFiles.forEach { file ->
                            Surface(
                                onClick = { model.open(Uri.parse(file.uri)) },
                                modifier = Modifier.fillMaxWidth(),
                                shape = androidx.compose.foundation.shape.RoundedCornerShape(14.dp),
                                color = Color.White.copy(alpha = 0.14f),
                                border = BorderStroke(1.dp, Color.White.copy(alpha = 0.2f))
                            ) {
                                Row(
                                    modifier = Modifier.padding(14.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(Icons.Default.Edit, contentDescription = null, tint = goldColor, modifier = Modifier.size(24.dp))
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(
                                        text = file.name,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = Color.White,
                                        fontWeight = FontWeight.Medium,
                                        modifier = Modifier.weight(1f),
                                        maxLines = 1
                                    )
                                    Icon(Icons.Default.Star, contentDescription = null, tint = Color.White.copy(alpha = 0.5f))
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(36.dp))

                // Settings & About Footer Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    TextButton(onClick = onSettings) {
                        Icon(Icons.Default.Settings, contentDescription = null, tint = goldColor)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Settings", color = goldColor, fontWeight = FontWeight.SemiBold)
                    }
                    Spacer(modifier = Modifier.width(20.dp))
                    TextButton(onClick = onAbout) {
                        Icon(Icons.Default.Info, contentDescription = null, tint = goldColor)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("About", color = goldColor, fontWeight = FontWeight.SemiBold)
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }
}
