package org.bunnypad.android

data class CodeLanguage(val name: String, val badge: String)

object LanguageDetector {
    fun detect(fileName: String, content: String): CodeLanguage? {
        val ext = fileName.substringAfterLast('.', "").lowercase()
        return when (ext) {
            "kt", "kts" -> CodeLanguage("Kotlin", "KT")
            "py" -> CodeLanguage("Python", "PY")
            "swift" -> CodeLanguage("Swift", "SW")
            "js", "jsx" -> CodeLanguage("JavaScript", "JS")
            "ts", "tsx" -> CodeLanguage("TypeScript", "TS")
            "html", "htm" -> CodeLanguage("HTML", "HTML")
            "xml" -> CodeLanguage("XML", "XML")
            "json" -> CodeLanguage("JSON", "JSON")
            "md" -> CodeLanguage("Markdown", "MD")
            "c", "h" -> CodeLanguage("C", "C")
            "cpp", "hpp", "cc" -> CodeLanguage("C++", "C++")
            "rs" -> CodeLanguage("Rust", "RS")
            "go" -> CodeLanguage("Go", "GO")
            "java" -> CodeLanguage("Java", "JAVA")
            "css" -> CodeLanguage("CSS", "CSS")
            "sql" -> CodeLanguage("SQL", "SQL")
            "sh", "bash" -> CodeLanguage("Shell", "SH")
            "rb" -> CodeLanguage("Ruby", "RB")
            "php" -> CodeLanguage("PHP", "PHP")
            "kt" -> CodeLanguage("Kotlin", "KT")
            else -> {
                when {
                    content.contains("fun main(") || content.contains("val ") -> CodeLanguage("Kotlin", "KT")
                    content.contains("def ") && content.contains("import ") -> CodeLanguage("Python", "PY")
                    content.contains("import SwiftUI") || content.contains("struct ") -> CodeLanguage("Swift", "SW")
                    content.contains("function ") || content.contains("const ") -> CodeLanguage("JavaScript", "JS")
                    content.contains("<?xml") -> CodeLanguage("XML", "XML")
                    content.contains("<html") -> CodeLanguage("HTML", "HTML")
                    else -> null
                }
            }
        }
    }
}
