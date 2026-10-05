package org.bunnypad.android

import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.nio.charset.CodingErrorAction

data class TextDocument(val text: String, val encoding: String = "UTF-8", val bom: Boolean = false, val newline: String = "\n") {
    fun bytes(): ByteArray {
        val normalized = text.replace("\r\n", "\n").replace("\r", "\n").replace("\n", newline)
        val encoder = charset(encoding).newEncoder()
            .onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)
        val buffer = encoder.encode(CharBuffer.wrap(normalized))
        val body = ByteArray(buffer.remaining()).also { buffer.get(it) }
        return (if (bom) prefix(encoding) else byteArrayOf()) + body
    }
    companion object {
        const val MAX_BYTES = 16 * 1024 * 1024
        const val MAX_CHARS = 4 * 1024 * 1024
        fun read(input: InputStream): TextDocument {
            val output = java.io.ByteArrayOutputStream()
            val buffer = ByteArray(8192)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                require(output.size() + count <= MAX_BYTES) { "Files larger than 16 MiB are not supported." }
                output.write(buffer, 0, count)
            }
            return decode(output.toByteArray())
        }
        fun decode(bytes: ByteArray): TextDocument {
            require(bytes.size <= MAX_BYTES) { "File is too large." }
            val encoding = when {
                bytes.starts(prefix("UTF-8")) -> "UTF-8"
                bytes.starts(prefix("UTF-16LE")) -> "UTF-16LE"
                bytes.starts(prefix("UTF-16BE")) -> "UTF-16BE"
                else -> "UTF-8"
            }
            val bom = bytes.starts(prefix(encoding))
            val body = if (bom) bytes.copyOfRange(prefix(encoding).size, bytes.size) else bytes
            var actual = encoding
            val raw = try { strictDecode(body, encoding) } catch (e: java.nio.charset.CharacterCodingException) {
                if (bom) throw IllegalArgumentException("The document has invalid ${encoding} data.", e)
                actual = "ISO-8859-1"
                strictDecode(body, actual)
            }
            require(raw.length <= MAX_CHARS) { "Documents larger than 4 million characters are not supported." }
            require(raw.none { it == '\u0000' || (it.code < 32 && it !in "\n\r\t") }) { "This file appears to contain binary data." }
            val crlf = Regex("\r\n").findAll(raw).count()
            val rest = raw.replace("\r\n", "")
            val cr = rest.count { it == '\r' }
            val lf = rest.count { it == '\n' }
            val newline = when { crlf > 0 && crlf >= cr && crlf >= lf -> "\r\n"; cr > lf -> "\r"; else -> "\n" }
            return TextDocument(raw.replace("\r\n", "\n").replace("\r", "\n"), actual, bom, newline)
        }
        private fun strictDecode(bytes: ByteArray, name: String) = charset(name).newDecoder()
            .onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)
            .decode(ByteBuffer.wrap(bytes)).toString()
        private fun charset(name: String) = java.nio.charset.Charset.forName(name)
        private fun prefix(name: String): ByteArray = when (name) {
            "UTF-8" -> byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte())
            "UTF-16LE" -> byteArrayOf(0xFF.toByte(), 0xFE.toByte())
            "UTF-16BE" -> byteArrayOf(0xFE.toByte(), 0xFF.toByte())
            else -> byteArrayOf()
        }
        private fun ByteArray.starts(prefix: ByteArray) = prefix.isNotEmpty() && size >= prefix.size && prefix.indices.all { this[it] == prefix[it] }
    }
}
