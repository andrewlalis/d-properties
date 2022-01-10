module d_properties.reader;

import std.stdio;
import std.file : exists, isFile, readText;
import std.range;
import std.conv : to;
import std.uni;
import std.format : format;
import std.regex : replaceAll, regex;
import std.string : strip;
import object : Exception;
import d_properties.properties : Properties;

/**
 * This exception is thrown when a properties file cannot be parsed.
 */
class PropertiesParseException : Exception {
    public const string filename;
    public const uint lineNumber;

    /** 
     * Constructs a parse exception.
     * Params:
     *   filename = The name of the file which gave a parse exception.
     *   lineNumber = The line number of the error, or -1 if none.
     *   message = The error message.
     */
    this(string filename, uint lineNumber, string message) {
        super(format(
            "Error parsing file \"%s\"%s: %s",
            filename,
            (lineNumber > 0) ? " on line " ~ to!string(lineNumber) : "",
            message
        ));
        this.filename = filename;
        this.lineNumber = lineNumber;
    }
}

/** 
 * Reads properties from a file.
 * Params:
 *   filename = The name of the file to read.
 * Returns: The properties that were read.
 */
public Properties readFromFile(string filename) {
    if (!exists(filename) || !isFile(filename)) {
        throw new PropertiesParseException(filename, -1, "File not found.");
    }
    Properties props;
    char[] content = replaceAll(readText(filename).strip(), regex(r"\r\n"), "\n").dup;
    uint lineNumber = 1;
    while (!content.empty) {
        while (content.front == '#' || content.front == '!') {
            parseComment(content, lineNumber);
        }
        if (!content.empty) {
            string key = parseKey(content, filename, lineNumber);
            string value = parseValue(content, filename, lineNumber);
            props[key] = value;
        }
    }
    return props;
}

/** 
 * Parses and discards a comment line from the input.
 * Params:
 *   content = The remaining file input.
 *   lineNumber = The current line number.
 */
private void parseComment(ref char[] content, ref uint lineNumber) {
    if (content.empty) return;
    dchar c = content.front;
    if (c == '#' || c == '!') {
        content.popFront; // Remove the comment char.
        while (c != '\n' && !content.empty) {
            c = content.front;
            content.popFront;
        }
        lineNumber++;
    }
}

/** 
 * Parses a property key from the input.
 * Params:
 *   content = The remaining file content to parse.
 *   filename = The name of the file.
 *   lineNumber = The current line number.
 * Returns: The key that was parsed.
 */
private string parseKey(ref char[] content, string filename, ref uint lineNumber) {
    // Start by stripping away all whitespace before the start of the key.
    while (content.front == ' ' || content.front == '\n' || content.front == '\t') {
        content.popFront;
    }
    dchar c = content.front;
    content.popFront;
    dchar[] keyChars = [c];
    bool keyFound = false;
    while (!keyFound) {
        if (content.empty) throw new PropertiesParseException(filename, lineNumber, "Unexpected end of file while parsing key.");
        c = content.front;
        content.popFront;
        // Detect the beginning of the separator.
        if (keyChars[$ - 1] != '\\' && (c == ' ' || c == '=' || c == ':')) {
            dchar separatorChar = ' ';
            if (c != ' ') separatorChar = c;
            while (c == ' ') {
                if (content.empty) throw new PropertiesParseException(filename, lineNumber, "Unexpected end of file while parsing separator.");
                c = content.front;
                if (c == ' ' || c == '=' || c == ':') {
                    content.popFront;
                    if (c == '=' || c == ':') break;
                }
            }
            // We have consumed as much whitespace as possible. If the separator char is a space, there's still the possibility to encounter a separator.
            if (separatorChar == ' ' && (c == '=' || c == ':')) {
                do {
                    if (content.empty)  throw new PropertiesParseException(filename, lineNumber, "Unexpected end of file while parsing separator trailing whitespace.");
                    c = content.front;
                    if (c == ' ') content.popFront;
                } while (c == ' ');
            }
            keyFound = true;
        } else if (keyChars[$ - 1] == '\\' && (c == ' ' || c == '=' || c == ':')) {
            keyChars[$ - 1] = c;
        } else if (c == '\n' || c == '\t') {
            throw new PropertiesParseException(filename, lineNumber, "Invalid key character.");
        } else {
            keyChars ~= c;
        }
    }
    return to!string(keyChars);
}

/** 
 * Parses a property value from the input.
 * Params:
 *   content = The remaining file content to parse.
 *   filename = The name of the file.
 *   lineNumber = The current line number.
 * Returns: The value that was parsed.
 */
private string parseValue(ref char[] content, string filename, ref uint lineNumber) {
    dchar[] valueChars = [];
    bool valueFound = false;
    while (!valueFound) {
        if (content.empty) { // If we've reached the end of the file, return this as the last value.
            return to!string(valueChars);
        }
        dchar c = content.front;
        content.popFront;
        // Check for some sort of escape sequence.
        if (c == '\\') {
            if (content.empty) throw new PropertiesParseException(filename, lineNumber, "Unexpected end of file while parsing escape sequence.");
            dchar next = content.front;
            content.popFront;
            if (next == '\\') {
                valueChars ~= '\\';
            } else if (next == '\n') {
                lineNumber++;
                do {
                    c = content.front;
                    if (c == ' ' || c == '\t') content.popFront;
                } while (c == ' ' || c == '\t');
            } else if (next == 'u') {
                valueChars ~= '\\';
                valueChars ~= 'u';
                for (int i = 0; i < 4; i++) {
                    if (content.empty || (!isAlphaNum(content.front))) throw new PropertiesParseException(filename, lineNumber, "Invalid unicode sequence.");
                    valueChars ~= content.front;
                    content.popFront;
                }
            } else {
                throw new Error("Unknown escape sequence: \"\\" ~ to!string(next) ~ "\"");
            }
        } else if (c == '\n') {
            valueFound = true;
            lineNumber++;
        } else {
            valueChars ~= c;
        }
    }
    return to!string(valueChars);
}
