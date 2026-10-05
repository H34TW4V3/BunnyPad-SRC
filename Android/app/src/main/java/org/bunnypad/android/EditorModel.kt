package org.bunnypad.android

import android.app.Application
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.util.AtomicFile
import androidx.compose.runtime.*
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import java.io.File
import kotlinx.coroutines.*
import org.json.JSONObject

data class RecentFile(val uri: String, val name: String)

class EditorModel(application: Application) : AndroidViewModel(application) {
    private val resolver = application.contentResolver
    private val prefs = application.getSharedPreferences("editor", 0)
    private val draft = AtomicFile(File(application.filesDir, "draft.json"))
    var value by mutableStateOf(TextFieldValue()); private set
    var format by mutableStateOf(TextDocument("")); private set
    var uri by mutableStateOf<Uri?>(null); private set
    var name by mutableStateOf("Untitled.txt"); private set
    var dirty by mutableStateOf(false); private set
    var busy by mutableStateOf(true); private set
    var message by mutableStateOf<String?>(null)
    var wrap by mutableStateOf(prefs.getBoolean("wrap", true))
    var fontSize by mutableIntStateOf(prefs.getInt("size", 18))
    var appearance by mutableIntStateOf(prefs.getInt("appearance", 0))
    var fontChoice by mutableIntStateOf(prefs.getInt("font_choice", 0))
    var showQuickNoteTile by mutableStateOf(prefs.getBoolean("showQuickNoteTile", true))
    var showPillOpen by mutableStateOf(prefs.getBoolean("pill_open", false))
    var showPillPrint by mutableStateOf(prefs.getBoolean("pill_print", false))
    var showPillCut by mutableStateOf(prefs.getBoolean("pill_cut", false))
    var showPillFind by mutableStateOf(prefs.getBoolean("pill_find", false))
    var isHome by mutableStateOf(true)
    var recentFiles by mutableStateOf(loadRecentFiles())
        private set

    private var savedText = ""
    private var savedFormat = format
    private val undo = ArrayDeque<Pair<TextFieldValue, TextDocument>>()
    private val redo = ArrayDeque<Pair<TextFieldValue, TextDocument>>()
    var canUndo by mutableStateOf(false); private set
    var canRedo by mutableStateOf(false); private set
    private var draftJob: Job? = null
    private val draftLock = Any()
    @Volatile private var draftRevision = 0L
    private var recoveryFailed = false

    init {
        viewModelScope.launch {
            val result = withContext(Dispatchers.IO) { runCatching {
                if (!draft.baseFile.exists() && !File(draft.baseFile.path + ".bak").exists()) null
                else JSONObject(draft.openRead().bufferedReader().use { it.readText() })
            } }
            runCatching {
                val j = result.getOrThrow()
                if (j != null) {
                    val text = j.getString("text")
                    value = TextFieldValue(text, TextRange(j.optInt("cursor").coerceIn(0, text.length)))
                    format = TextDocument("", j.getString("encoding"), j.getBoolean("bom"), j.getString("newline"))
                    uri = j.optString("uri").takeIf { it.isNotEmpty() }?.let(Uri::parse)
                    name = j.getString("name")
                    savedText = j.getString("savedText")
                    savedFormat = TextDocument("", j.optString("savedEncoding", format.encoding), j.optBoolean("savedBom", format.bom), j.optString("savedNewline", format.newline))
                    updateDirty()
                }
            }.onFailure { recoveryFailed = true; message = "Draft recovery failed. The recovery file will be retained until you edit or start another document." }
            busy = false
        }
    }

    private fun loadRecentFiles(): List<RecentFile> {
        val jsonStr = prefs.getString("recent_files", "[]") ?: "[]"
        val list = mutableListOf<RecentFile>()
        runCatching {
            val arr = org.json.JSONArray(jsonStr)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                list.add(RecentFile(obj.getString("uri"), obj.getString("name")))
            }
        }
        return list
    }

    private fun addRecentFile(targetUri: Uri, title: String) {
        val uriStr = targetUri.toString()
        val mutable = recentFiles.toMutableList()
        mutable.removeAll { it.uri == uriStr }
        mutable.add(0, RecentFile(uriStr, title))
        if (mutable.size > 10) mutable.removeAt(mutable.size - 1)
        recentFiles = mutable
        val arr = org.json.JSONArray()
        for (f in mutable) {
            arr.put(JSONObject().put("uri", f.uri).put("name", f.name))
        }
        prefs.edit().putString("recent_files", arr.toString()).apply()
    }

    fun edit(next: TextFieldValue) {
        if (busy) return
        if (next.text.length > TextDocument.MAX_CHARS) { message = "The editor limit is 4 million characters."; return }
        if (next.text != value.text) {
            rememberUndo()
            redo.clear()
        }
        recoveryFailed = false
        value = next
        updateDirty()
        historyState()
        scheduleDraft()
    }
    private fun rememberUndo() {
        undo.addLast(value to format)
        while (undo.size > 100 || undo.sumOf { it.first.text.length.toLong() } > 8 * 1024 * 1024L) undo.removeFirst()
    }
    fun undo() {
        if (busy || undo.isEmpty()) return
        redo.addLast(value to format)
        val previous = undo.removeLast(); value = previous.first; format = previous.second
        updateDirty(); historyState(); scheduleDraft()
    }
    fun redo() {
        if (busy || redo.isEmpty()) return
        rememberUndo()
        val next = redo.removeLast(); value = next.first; format = next.second
        updateDirty(); historyState(); scheduleDraft()
    }
    fun useUtf8() {
        if (busy) return
        rememberUndo(); redo.clear(); format = format.copy(encoding = "UTF-8", bom = false)
        updateDirty(); historyState(); scheduleDraft()
    }
    private fun updateDirty() { dirty = value.text != savedText || format != savedFormat }
    private fun historyState() { canUndo = undo.isNotEmpty(); canRedo = redo.isNotEmpty() }
    fun newDocument() {
        if (busy) return
        recoveryFailed = false
        value = TextFieldValue(); format = TextDocument(""); savedFormat = format; savedText = ""
        uri = null; name = "Untitled.txt"; dirty = false
        undo.clear(); redo.clear(); historyState(); isHome = false; scheduleDraft()
    }
    fun quickNote() {
        if (busy) return
        recoveryFailed = false
        val timestamp = java.time.LocalDateTime.now().format(java.time.format.DateTimeFormatter.ofPattern("MMM d, yyyy, h:mm a"))
        value = TextFieldValue("--- Quick Note ($timestamp) ---\n\n", TextRange(value.text.length))
        format = TextDocument("")
        savedFormat = format
        savedText = value.text
        uri = null
        name = "QuickNote.txt"
        dirty = false
        undo.clear()
        redo.clear()
        historyState()
        isHome = false
        scheduleDraft()
    }
    fun goHome() {
        flushDraft()
        isHome = true
    }
    fun open(target: Uri) {
        if (busy) return
        busy = true
        viewModelScope.launch {
            val result = withContext(Dispatchers.IO) { runCatching {
                val doc = resolver.openInputStream(target)?.use(TextDocument::read) ?: error("Cannot read this file.")
                doc to displayName(target)
            } }
            result.onSuccess { (doc, title) ->
                recoveryFailed = false
                value = TextFieldValue(doc.text); format = doc.copy(text = "")
                savedText = doc.text; savedFormat = format; uri = target; name = title; dirty = false
                undo.clear(); redo.clear(); historyState(); isHome = false
                addRecentFile(target, title)
                persistPermission(target)
            }.onFailure { message = "Open failed: ${it.message}" }
            busy = false; scheduleDraft()
        }
    }
    fun save(target: Uri, onSuccess: () -> Unit = {}) {
        if (busy) return
        busy = true
        val snapshot = format.copy(text = value.text)
        viewModelScope.launch {
            // Encoding must succeed before the provider is opened for truncation.
            val result = withContext(Dispatchers.IO) { runCatching {
                val bytes = snapshot.bytes()
                resolver.openOutputStream(target, "wt")?.use { it.write(bytes); it.flush() }
                    ?: error("Cannot write this file.")
                runCatching { displayName(target) }.getOrDefault(name)
            } }
            result.onSuccess { title ->
                uri = target; name = title; savedText = snapshot.text; savedFormat = format; updateDirty()
                addRecentFile(target, title)
                persistPermission(target); message = "Saved ${name}"
            }.onFailure { message = "Save failed; your draft is retained. ${it.message}. Use Save As or Use UTF-8 if needed." }
            busy = false; scheduleDraft()
            if (result.isSuccess) onSuccess()
        }
    }
    private fun persistPermission(target: Uri) {
        runCatching { resolver.takePersistableUriPermission(target, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION) }
            .recoverCatching { resolver.takePersistableUriPermission(target, Intent.FLAG_GRANT_READ_URI_PERMISSION) }
    }
    private fun displayName(target: Uri): String = resolver.query(target, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
        if (it.moveToFirst()) it.getString(0) else "Note.txt"
    } ?: "Note.txt"
    fun savePreferences() {
        prefs.edit()
            .putBoolean("wrap", wrap)
            .putInt("size", fontSize)
            .putInt("appearance", appearance)
            .putBoolean("showQuickNoteTile", showQuickNoteTile)
            .putInt("font_choice", fontChoice)
            .apply()
    }
    fun shareText(context: android.content.Context) {
        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            putExtra(Intent.EXTRA_TEXT, value.text)
            type = "text/plain"
        }
        val shareIntent = Intent.createChooser(sendIntent, "Share note via")
        context.startActivity(shareIntent)
    }
    fun copyText(clipboardManager: androidx.compose.ui.platform.ClipboardManager) {
        val sel = value.selection
        val text = value.text
        val toCopy = if (sel.collapsed) text else text.substring(sel.min.coerceAtLeast(0), sel.max.coerceAtMost(text.length))
        clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(toCopy))
        message = "Copied to clipboard"
    }
    fun cutText(clipboardManager: androidx.compose.ui.platform.ClipboardManager) {
        val sel = value.selection
        val text = value.text
        if (sel.collapsed) return
        val toCopy = text.substring(sel.min.coerceAtLeast(0), sel.max.coerceAtMost(text.length))
        clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(toCopy))
        val newText = text.removeRange(sel.min.coerceAtLeast(0), sel.max.coerceAtMost(text.length))
        edit(TextFieldValue(newText, TextRange(sel.min.coerceAtMost(newText.length))))
        message = "Cut to clipboard"
    }
    fun pasteText(clipboardManager: androidx.compose.ui.platform.ClipboardManager) {
        val pasted = clipboardManager.getText()?.text ?: return
        val sel = value.selection
        val text = value.text
        val newText = text.replaceRange(sel.min.coerceAtMost(text.length), sel.max.coerceAtMost(text.length), pasted)
        val newCursor = sel.min + pasted.length
        edit(TextFieldValue(newText, TextRange(newCursor.coerceAtMost(newText.length))))
    }
    fun printDocument(context: android.content.Context, documentName: String) {
        val printManager = context.getSystemService(android.content.Context.PRINT_SERVICE) as? android.print.PrintManager ?: return
        val printAdapter = object : android.print.PrintDocumentAdapter() {
            override fun onLayout(
                oldAttributes: android.print.PrintAttributes?,
                newAttributes: android.print.PrintAttributes?,
                cancellationSignal: android.os.CancellationSignal?,
                callback: android.print.PrintDocumentAdapter.LayoutResultCallback?,
                extras: android.os.Bundle?
            ) {
                if (cancellationSignal?.isCanceled == true) {
                    callback?.onLayoutCancelled()
                    return
                }
                val pInfo = android.print.PrintDocumentInfo.Builder(documentName)
                    .setContentType(android.print.PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                    .setPageCount(android.print.PrintDocumentInfo.PAGE_COUNT_UNKNOWN)
                    .build()
                callback?.onLayoutFinished(pInfo, true)
            }

            override fun onWrite(
                pages: Array<out android.print.PageRange>?,
                destination: android.os.ParcelFileDescriptor?,
                cancellationSignal: android.os.CancellationSignal?,
                callback: android.print.PrintDocumentAdapter.WriteResultCallback?
            ) {
                try {
                    val input = value.text.toByteArray(Charsets.UTF_8)
                    java.io.FileOutputStream(destination?.fileDescriptor).use { it.write(input) }
                    callback?.onWriteFinished(arrayOf(android.print.PageRange.ALL_PAGES))
                } catch (e: Exception) {
                    callback?.onWriteFailed(e.localizedMessage)
                }
            }
        }
        printManager.print("BunnyPad Document - $documentName", printAdapter, android.print.PrintAttributes.Builder().build())
    }
    private fun snapshot() = JSONObject().put("text", value.text).put("cursor", value.selection.end)
        .put("savedText", savedText).put("name", name).put("uri", uri?.toString() ?: "")
        .put("encoding", format.encoding).put("bom", format.bom).put("newline", format.newline)
        .put("savedEncoding", savedFormat.encoding).put("savedBom", savedFormat.bom).put("savedNewline", savedFormat.newline).toString()
    private fun writeDraft(data: String, revision: Long) = synchronized(draftLock) {
        if (revision != draftRevision) return@synchronized
        var stream: java.io.FileOutputStream? = null
        try {
            stream = draft.startWrite(); stream.write(data.toByteArray(Charsets.UTF_8)); draft.finishWrite(stream)
        } catch (e: Exception) { draft.failWrite(stream); throw e }
    }
    private fun scheduleDraft() {
        if (recoveryFailed) return
        draftJob?.cancel()
        val revision = ++draftRevision
        draftJob = viewModelScope.launch {
            delay(500)
            val data = snapshot()
            try { withContext(Dispatchers.IO) { writeDraft(data, revision) } }
            catch (e: CancellationException) { throw e }
            catch (e: Exception) { message = "Could not store the recovery draft: ${e.message}" }
        }
    }
    // Flush on backgrounding as well as after a short debounce during editing.
    fun flushDraft() {
        if (busy || recoveryFailed) return
        draftJob?.cancel()
        val revision = ++draftRevision
        runCatching { writeDraft(snapshot(), revision) }.onFailure { message = "Could not store the recovery draft." }
    }
}
