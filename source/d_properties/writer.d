module d_properties.writer;

import std.stdio : File;
import std.algorithm.sorting : sort;
import std.regex;
import d_properties.properties : Properties;

/** 
 * The style of separator to use when writing.
 */
public enum SeparatorStyle : string {
    EQUALS = "=",
    EQUALS_SPACED = " = ",
    COLON = ":",
    COLON_SPACED = " : ",
    SPACE = " "
}

/** 
 * The style of comment to use when writing.
 */
public enum CommentStyle : string {
    HASHTAG = "#",
    EXCLAMATION = "!"
}

/** 
 * Writes the given properties to a file.
 * Params:
 *   props = The properties to write.
 *   filename = The name of the file to write to.
 *   comment = A comment to place at the top of the file.
 *   separatorStyle = The style to use when separating keys and values.
 *   commentStyle = The style to use for comments.
 */
public void writeToFile(
    Properties props,
    string filename,
    string comment = null,
    SeparatorStyle separatorStyle = SeparatorStyle.EQUALS_SPACED,
    CommentStyle commentStyle = CommentStyle.HASHTAG
) {
    auto f = File(filename, "w");
    string commentMarker = cast(string) commentStyle;
    string separator = cast(string) separatorStyle;
    if (comment != null) {
        f.writefln("%s %s", commentMarker, comment);
    }
    auto keys = props.values.keys;
    keys.sort(); // Sort keys to make file writing deterministic.
    foreach (key; keys) {
        f.writefln("%s%s%s", sanitizeKey(key), separator, sanitizeValue(props[key]));
    }
    f.close;
}

private string sanitizeKey(string key) {
    return key.replaceAll(regex(" "), "\\ ")
        .replaceAll(regex(":"), "\\:")
        .replaceAll(regex("="), "\\=");
}

private string sanitizeValue(string value) {
    return value.replaceAll(regex("\\\\(?=[^u]|$)"), "\\\\");
}
