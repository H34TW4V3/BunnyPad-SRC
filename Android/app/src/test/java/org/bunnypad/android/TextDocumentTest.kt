package org.bunnypad.android

import org.junit.Assert.*
import org.junit.Test
import java.io.ByteArrayInputStream
import java.nio.charset.CharacterCodingException

class TextDocumentTest {
    @Test fun utf8AndBomRoundTrips() {
        for (bom in listOf(false, true)) {
            val original = TextDocument("Bunny 🐰\nA café", bom = bom)
            val bytes = original.bytes()
            assertEquals(original, TextDocument.decode(bytes))
            assertArrayEquals(bytes, TextDocument.decode(bytes).bytes())
        }
    }
    @Test fun utf16AndLineEndingsRoundTrip() {
        for (encoding in listOf("UTF-16LE", "UTF-16BE")) {
            for (ending in listOf("\n", "\r\n", "\r")) {
                val original = TextDocument("Hello 🐰\nWorld\n", encoding, true, ending)
                val bytes = original.bytes()
                assertEquals(original, TextDocument.read(ByteArrayInputStream(bytes)))
                assertArrayEquals(bytes, TextDocument.decode(bytes).bytes())
            }
        }
    }
    @Test fun latin1IsPreserved() {
        val bytes = "Café\r\n".toByteArray(Charsets.ISO_8859_1)
        val decoded = TextDocument.decode(bytes)
        assertEquals("ISO-8859-1", decoded.encoding)
        assertEquals("Café\n", decoded.text)
        assertArrayEquals(bytes, decoded.bytes())
    }
    @Test fun mixedEndingsUsePredominantStyle() {
        val decoded = TextDocument.decode("a\r\nb\nc\n".toByteArray())
        assertEquals("\n", decoded.newline)
        assertEquals("a\nb\nc\n", decoded.text)
    }
    @Test fun emptyDocument() {
        assertEquals(TextDocument(""), TextDocument.decode(byteArrayOf()))
    }
    @Test(expected = IllegalArgumentException::class) fun binaryRejected() {
        TextDocument.decode(byteArrayOf(65, 0, 66))
    }
    @Test(expected = IllegalArgumentException::class) fun malformedBomRejected() {
        TextDocument.decode(byteArrayOf(0xEF.toByte(), 0xBB.toByte(), 0xBF.toByte(), 0xFF.toByte()))
    }
    @Test(expected = IllegalArgumentException::class) fun oversizeRejected() {
        TextDocument.read(ByteArrayInputStream(ByteArray(TextDocument.MAX_BYTES + 1)))
    }
    @Test(expected = IllegalArgumentException::class) fun characterLimitRejected() {
        TextDocument.decode(ByteArray(TextDocument.MAX_CHARS + 1) { 65 })
    }
    @Test(expected = CharacterCodingException::class) fun latin1CannotSilentlyLoseEmoji() {
        TextDocument("🐰", "ISO-8859-1").bytes()
    }
    @Test fun conversionToUtf8KeepsEmoji() {
        val document = TextDocument("Café 🐰", "ISO-8859-1").copy(encoding = "UTF-8")
        assertEquals(document, TextDocument.decode(document.bytes()))
    }
}
