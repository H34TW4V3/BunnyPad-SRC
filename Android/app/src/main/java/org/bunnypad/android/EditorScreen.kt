package org.bunnypad.android

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.bunnypad.android.theme.BunnyPadTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditorScreen(model: EditorModel) {
    val dark = when (model.appearance) { 1 -> false; 2 -> true; else -> isSystemInDarkTheme() }
    BunnyPadTheme(darkTheme = dark, dynamicColor = false) {
        val context = LocalContext.current
        var dialog by rememberSaveable { mutableStateOf("") }
        var showFileAboutSheet by remember { mutableStateOf(false) }
        var showSaveSheet by remember { mutableStateOf(false) }
        var showUnsavedSheet by remember { mutableStateOf(false) }
        var menuExpanded by remember { mutableStateOf(false) }
        var pending by rememberSaveable { mutableStateOf("") }
        var saveThen by rememberSaveable { mutableStateOf("") }
        var query by rememberSaveable { mutableStateOf("") }
        var replacement by rememberSaveable { mutableStateOf("") }
        var line by rememberSaveable { mutableStateOf("") }

        var customFileName by rememberSaveable { mutableStateOf("Note") }
        var customFileExt by rememberSaveable { mutableStateOf(".txt") }

        val open = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
            if (uri != null) model.open(uri)
        }
        fun perform(action: String) {
            when (action) {
                "new" -> model.newDocument()
                "open" -> open.launch(arrayOf("*/*"))
            }
        }
        val create = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/plain")) { uri ->
            val after = saveThen
            saveThen = ""
            if (uri != null) model.save(uri) { perform(after) }
        }
        fun save(after: String = "") {
            val uri = model.uri
            if (uri == null) {
                saveThen = after
                showSaveSheet = true
            } else {
                model.save(uri) { perform(after) }
            }
        }
        fun guarded(action: String) {
            if (model.dirty) { pending = action; showUnsavedSheet = true } else perform(action)
        }
        fun findNext() {
            if (query.isEmpty()) return
            val text = model.value.text
            val start = model.value.selection.max.coerceAtMost(text.length)
            val index = text.indexOf(query, start, ignoreCase = true).let {
                if (it < 0) text.indexOf(query, ignoreCase = true) else it
            }
            if (index >= 0) model.edit(model.value.copy(selection = TextRange(index, index + query.length)))
            else model.message = "No matches found."
        }

        val backgroundBrush = Brush.linearGradient(
            colors = listOf(Color(0xFF1A61AE), Color(0xFF7341BB), Color(0xFFC545B6))
        )
        val pillBrush = Brush.linearGradient(
            colors = listOf(Color(0xFF1F68B6), Color(0xFF8042C7), Color(0xFFD34CC2))
        )

        Box(modifier = Modifier.fillMaxSize().background(backgroundBrush)) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .systemBarsPadding()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.Center
            ) {
                // Floating Pill Toolbar at the top spanning full width with center-aligned content
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(50),
                    tonalElevation = 8.dp,
                    shadowElevation = 8.dp,
                    color = Color.Transparent
                ) {
                    Box(
                        modifier = Modifier
                            .background(pillBrush)
                            .border(1.dp, Color.White.copy(alpha = 0.3f), androidx.compose.foundation.shape.RoundedCornerShape(50)),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(
                            modifier = Modifier
                                .horizontalScroll(rememberScrollState())
                                .padding(horizontal = 8.dp, vertical = 4.dp),
                            horizontalArrangement = Arrangement.Center,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            ToolButton(Icons.Default.Home, "Home") { model.goHome() }
                            ToolButton(Icons.Default.Add, "New") { guarded("new") }
                            ToolButton(Icons.Default.Done, "Save") { save() }
                            ToolButton(Icons.Default.Share, "Share") { model.shareText(context) }

                            // Hamburger Menu (Overflow) with M3 styling and rounded edges containing Undo/Redo, Open, Share, Find, Settings, File Info
                            Box {
                                ToolButton(Icons.Default.Menu, "Menu") { menuExpanded = true }
                                DropdownMenu(
                                    expanded = menuExpanded,
                                    onDismissRequest = { menuExpanded = false },
                                    shape = androidx.compose.foundation.shape.RoundedCornerShape(16.dp),
                                    containerColor = MaterialTheme.colorScheme.surface,
                                    tonalElevation = 8.dp
                                ) {
                                    DropdownMenuItem(text = { Text("Undo") }, onClick = { menuExpanded = false; model.undo() }, enabled = model.canUndo, leadingIcon = { Icon(Icons.Default.Refresh, contentDescription = null) })
                                    DropdownMenuItem(text = { Text("Redo") }, onClick = { menuExpanded = false; model.redo() }, enabled = model.canRedo, leadingIcon = { Icon(Icons.Default.PlayArrow, contentDescription = null) })
                                    HorizontalDivider()
                                    DropdownMenuItem(text = { Text("Open") }, onClick = { menuExpanded = false; guarded("open") }, leadingIcon = { Icon(Icons.Default.Menu, contentDescription = null) })
                                    DropdownMenuItem(text = { Text("Share") }, onClick = { menuExpanded = false; model.shareText(context) }, leadingIcon = { Icon(Icons.Default.Share, contentDescription = null) })
                                    DropdownMenuItem(text = { Text("Find / Replace") }, onClick = { menuExpanded = false; dialog = "find" }, leadingIcon = { Icon(Icons.Default.Search, contentDescription = null) })
                                    DropdownMenuItem(text = { Text("Settings") }, onClick = { menuExpanded = false; dialog = "settings" }, leadingIcon = { Icon(Icons.Default.Settings, contentDescription = null) })
                                    DropdownMenuItem(text = { Text("File Information") }, onClick = { menuExpanded = false; showFileAboutSheet = true }, leadingIcon = { Icon(Icons.Default.Info, contentDescription = null) })
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // File name chip beneath the editor pill
                Surface(
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(50),
                    color = Color.Black.copy(alpha = 0.3f),
                    border = BorderStroke(1.dp, Color.White.copy(alpha = 0.2f)),
                    modifier = Modifier.padding(vertical = 2.dp)
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .background(if (model.dirty) Color(0xFFFFC43B) else Color.Green, androidx.compose.foundation.shape.CircleShape)
                        )
                        Text(
                            text = model.name + if (model.dirty) " •" else "",
                            style = MaterialTheme.typography.labelSmall,
                            color = Color.White,
                            maxLines = 1
                        )
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                if (model.busy) LinearProgressIndicator(Modifier.fillMaxWidth(), color = Color.White)

                // Text Editor area taking all remaining full-screen space directly over gradient (no island container)
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    val horizontal = rememberScrollState()
                    val editorModifier = Modifier.fillMaxSize()
                        .then(if (model.wrap) Modifier else Modifier.horizontalScroll(horizontal))
                    val selectedFont = when (model.fontChoice) {
                        1 -> FontFamily.SansSerif
                        2 -> FontFamily.Serif
                        else -> FontFamily.Monospace
                    }
                    BasicTextField(
                        value = model.value, onValueChange = model::edit, readOnly = model.busy,
                        textStyle = TextStyle(color = Color.White, fontFamily = selectedFont, fontSize = model.fontSize.sp),
                        cursorBrush = SolidColor(Color(0xFFFFC43B)),
                        modifier = editorModifier.testTag("noteEditor"),
                        decorationBox = { inner ->
                            Box {
                                if (model.value.text.isEmpty()) Text("A little space for your thoughts…", color = Color.White.copy(alpha = 0.6f))
                                inner()
                            }
                        }
                    )
                }

                // Code Language Detection Tab (if code file)
                val lang = remember(model.name, model.value.text) {
                    LanguageDetector.detect(model.name, model.value.text)
                }
                if (lang != null) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(50),
                        color = Color.Transparent
                    ) {
                        Box(modifier = Modifier.background(pillBrush).border(1.dp, Color.White.copy(alpha = 0.3f), androidx.compose.foundation.shape.RoundedCornerShape(50))) {
                            Row(
                                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Surface(
                                    shape = androidx.compose.foundation.shape.RoundedCornerShape(50),
                                    color = Color(0xFFFFC43B)
                                ) {
                                    Text(
                                        text = lang.badge,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color.Black,
                                        fontWeight = FontWeight.Bold,
                                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                                    )
                                }
                                Text(
                                    text = "Language: ${lang.name}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = Color.White,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Status bar at the bottom using all available width with SpaceBetween
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 2.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val text = model.value.text
                    val cursor = model.value.selection.end.coerceIn(0, text.length)
                    val ln = remember(text, cursor) { text.take(cursor).count { it == '\n' } + 1 }
                    val col = if (cursor == 0) 1 else cursor - text.lastIndexOf('\n', cursor - 1)
                    Text(
                        "Ln $ln · Col $col",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White.copy(alpha = 0.85f)
                    )
                    Text(
                        "${text.length} chars · ${model.format.encoding} · ${when(model.format.newline) { "\r\n" -> "CRLF"; "\r" -> "CR"; else -> "LF" }}",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White.copy(alpha = 0.85f)
                    )
                }
            }
        }

        // Unsaved Changes Bottom Sheet
        if (showUnsavedSheet) {
            ModalBottomSheet(
                onDismissRequest = { showUnsavedSheet = false; pending = "" }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    Text("Save your changes?", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Save this note before opening another document or starting a new one.", style = MaterialTheme.typography.bodyMedium)
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = {
                            val action = pending
                            pending = ""
                            showUnsavedSheet = false
                            save(action)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Save")
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedButton(
                        onClick = {
                            val action = pending
                            pending = ""
                            showUnsavedSheet = false
                            perform(action)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Discard changes")
                    }
                    Spacer(modifier = Modifier.height(36.dp))
                }
            }
        }

        // Custom Save Bottom Sheet (Name, Type, Location)
        if (showSaveSheet) {
            ModalBottomSheet(
                onDismissRequest = { showSaveSheet = false }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    Text("Save Document", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(16.dp))

                    OutlinedTextField(
                        value = customFileName,
                        onValueChange = { customFileName = it },
                        label = { Text("File name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(modifier = Modifier.height(12.dp))

                    Text("File type / extension:", style = MaterialTheme.typography.labelMedium)
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        modifier = Modifier.horizontalScroll(rememberScrollState()),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        listOf(".txt", ".kt", ".py", ".md", ".json", ".html", ".js", ".xml").forEach { ext ->
                            FilterChip(
                                selected = customFileExt == ext,
                                onClick = { customFileExt = ext },
                                label = { Text(ext) }
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Button(
                        onClick = {
                            showSaveSheet = false
                            val fullName = customFileName.removeSuffix(customFileExt) + customFileExt
                            create.launch(fullName)
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Choose Save Location & Save")
                    }

                    Spacer(modifier = Modifier.height(36.dp))
                }
            }
        }

        // File Information Bottom Sheet
        if (showFileAboutSheet) {
            val text = model.value.text
            val wordCount = remember(text) { if (text.isBlank()) 0 else text.trim().split(Regex("\\s+")).size }
            val lineCount = remember(text) { text.count { it == '\n' } + 1 }

            ModalBottomSheet(
                onDismissRequest = { showFileAboutSheet = false }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(24.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    Text("File Information", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(16.dp))

                    Surface(
                        modifier = Modifier.fillMaxWidth(),
                        shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
                        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                    ) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text("File Name: ${model.name}", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
                            Text("Characters: ${text.length}", style = MaterialTheme.typography.bodySmall)
                            Text("Words: $wordCount", style = MaterialTheme.typography.bodySmall)
                            Text("Lines: $lineCount", style = MaterialTheme.typography.bodySmall)
                            Text("Encoding: ${model.format.encoding}", style = MaterialTheme.typography.bodySmall)
                            Text("Line Ending: ${when(model.format.newline) { "\r\n" -> "CRLF"; "\r" -> "CR"; else -> "LF" }}", style = MaterialTheme.typography.bodySmall)
                        }
                    }

                    Spacer(modifier = Modifier.height(36.dp))
                }
            }
        }

        when (dialog) {
            "find" -> {
                var findReplaceTab by rememberSaveable { mutableIntStateOf(0) }
                ModalBottomSheet(
                    onDismissRequest = { dialog = "" }
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp)
                            .verticalScroll(rememberScrollState())
                    ) {
                        // M3 style rounded tabs for Find/Replace
                        TabRow(
                            selectedTabIndex = findReplaceTab,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(androidx.compose.foundation.shape.RoundedCornerShape(16.dp)),
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        ) {
                            Tab(
                                selected = findReplaceTab == 0,
                                onClick = { findReplaceTab = 0 },
                                text = { Text("Find") },
                                modifier = Modifier.clip(androidx.compose.foundation.shape.RoundedCornerShape(16.dp))
                            )
                            Tab(
                                selected = findReplaceTab == 1,
                                onClick = { findReplaceTab = 1 },
                                text = { Text("Replace") },
                                modifier = Modifier.clip(androidx.compose.foundation.shape.RoundedCornerShape(16.dp))
                            )
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        OutlinedTextField(
                            value = query,
                            onValueChange = { query = it },
                            label = { Text("Find text") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth()
                        )
                        if (findReplaceTab == 1) {
                            Spacer(modifier = Modifier.height(12.dp))
                            OutlinedTextField(
                                value = replacement,
                                onValueChange = { replacement = it },
                                label = { Text("Replace with") },
                                singleLine = true,
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                        Spacer(modifier = Modifier.height(20.dp))
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Button(onClick = ::findNext, enabled = query.isNotEmpty(), modifier = Modifier.weight(1f)) {
                                Text("Find Next")
                            }
                            if (findReplaceTab == 1) {
                                Button(onClick = {
                                    val v = model.value
                                    if (v.selection.min != v.selection.max && v.text.substring(v.selection.min, v.selection.max).equals(query, true)) {
                                        model.edit(TextFieldValue(v.text.replaceRange(v.selection.min, v.selection.max, replacement), TextRange(v.selection.min + replacement.length)))
                                    }
                                    findNext()
                                }, enabled = query.isNotEmpty(), modifier = Modifier.weight(1f)) {
                                    Text("Replace")
                                }
                                Button(onClick = {
                                    if (query.isNotEmpty()) model.edit(TextFieldValue(model.value.text.replace(query, replacement, ignoreCase = true)))
                                }, enabled = query.isNotEmpty(), modifier = Modifier.weight(1f)) {
                                    Text("Replace All")
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(36.dp))
                    }
                }
            }
            "settings" -> {
                ModalBottomSheet(
                    onDismissRequest = { dialog = "" }
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
                            Checkbox(model.wrap, { model.wrap = it; model.savePreferences() })
                            Text("Word wrap", Modifier.padding(start = 8.dp))
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Checkbox(model.showQuickNoteTile, { model.showQuickNoteTile = it; model.savePreferences() })
                            Text("Enable Quick Settings Tile", Modifier.padding(start = 8.dp))
                        }

                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Text size: ${model.fontSize} sp")
                        Slider(model.fontSize.toFloat(), { model.fontSize = it.toInt(); model.savePreferences() }, valueRange = 12f..32f, steps = 19)

                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Font Family")
                        listOf("Monospace", "Sans-Serif", "Serif").forEachIndexed { index, title ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                RadioButton(model.fontChoice == index, { model.fontChoice = index; model.savePreferences() })
                                Text(title, Modifier.padding(start = 8.dp))
                            }
                        }

                        Spacer(modifier = Modifier.height(16.dp))
                        Text("Appearance")
                        listOf("System theme", "Light", "Dark").forEachIndexed { index, title ->
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                RadioButton(model.appearance == index, { model.appearance = index; model.savePreferences() })
                                Text(title, Modifier.padding(start = 8.dp))
                            }
                        }

                        Spacer(modifier = Modifier.height(36.dp))
                    }
                }
            }
            "line" -> AlertDialog(onDismissRequest = { dialog = "" }, title = { Text("Go to Line") },
                text = { OutlinedTextField(line, { line = it }, label = { Text("Line number") }, singleLine = true) },
                confirmButton = { TextButton(onClick = {
                    val n = line.toIntOrNull()
                    val starts = listOf(0) + model.value.text.indices.filter { model.value.text[it] == '\n' }.map { it + 1 }
                    if (n != null && n in 1..starts.size) {
                        model.edit(model.value.copy(selection = TextRange(starts[n - 1]))); dialog = ""
                    } else model.message = "Enter a line from 1 to ${starts.size}."
                }) { Text("Go") } }, dismissButton = { TextButton(onClick = { dialog = "" }) { Text("Cancel") } })
            "about" -> {}
        }
        model.message?.let { message ->
            AlertDialog(onDismissRequest = { model.message = null }, title = { Text("BunnyPad") }, text = { Text(message) },
                confirmButton = { TextButton(onClick = { model.message = null }) { Text("OK") } })
        }
    }
}

@Composable
private fun ToolButton(icon: ImageVector, label: String, enabled: Boolean = true, onClick: () -> Unit) {
    TextButton(
        onClick = onClick,
        enabled = enabled,
        colors = ButtonDefaults.textButtonColors(contentColor = Color.White),
        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp)
            )
        }
    }
}
