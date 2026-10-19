import UniformTypeIdentifiers

/// Text/source extensions from Notepad++'s built-in language catalogue.
/// Source: https://github.com/notepad-plus-plus/notepad-plus-plus/blob/master/PowerEditor/src/langs.model.xml
enum TextFileTypes {
    static let filenameExtensions = """
        txt as mx ada ads adb asm mib asp aspx au3 avs avsi bc cln bash sh bsh csh bash_profile bashrc profile bat cmd nt bb c lex ml mli sml thy cmake cbl cbd cdb cdc cob cpy copy lst orc sco csd coffee litcoffee cpp cxx cc h hh hpp hxx ino cs css d diff patch erl hrl err ans src em forth f for f90 f95 f2k f23 f77 bas bi go gui hs lhs las hws html htm shtml shtm xhtml xht hta ini inf url wer iss hex java js jsm jsx mjs vue json json5 jsonc jsp kix lsp lisp tex sty lua mak mk m tsql mms nim tab spf nfo nsi nsh osx mm pas pp p inc lpr dpr pl pm plx t php php3 php4 php5 phps phpt phtml ps ps1 psm1 psd1 properties conf cf cfg gitattributes gitconfig gitmodules editorconfig pb py pyw pyx pxd pxi pyi gd r s splus raku rakumod rakudoc rakutest p6 pm6 pod6 t6 r2 r3 reb reg rc rb rbw rs sas scm smd ss st stx scp out sql mot srec swift tcl itcl tek toml vb vba vbs t2t ts tsx v sv vh svh vhd vhdl pro cl i pack ph xml xaml xsl xslt xsd xul kml svg mxml xsml wsdl xlf xliff xbl sxbl sitemap gml gpx plist slnx targets vcproj vcxproj csproj csxproj vbproj dbproj dproj wxs wixproj ilproj yml yaml
        """.split(separator: " ").map(String.init)

    static var writableContentTypes: [UTType] {
        var identifiers = Set<String>()
        // Data permits extensionless names (Makefile, Rakefile) and custom text extensions.
        return ([UTType.plainText] + filenameExtensions.compactMap {
            UTType(filenameExtension: $0)
        } + [.data]).filter { identifiers.insert($0.identifier).inserted }
    }

    // Some source extensions are registered as data rather than text by other apps.
    // Validate the actual bytes in TextSnapshot.decode instead of trusting the extension.
    static let readableContentTypes: [UTType] = [.data]
}
