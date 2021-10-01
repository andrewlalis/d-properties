module d_properties.reader;

import std.stdio;
import std.file;
import std.range;
import std.array;
import std.conv;
import std.uni;
import std.regex;
import d_properties.properties : Properties;

Properties readFromFile(string filename) {
    if (!exists(filename) || !isFile(filename)) {
        throw new Error("Invalid filename.");
    }
    Properties props;
    auto r = regex(r"\r\n");
    char[] content = replaceAll(readText(filename), r, "\n").dup;
    while (!content.empty) {
        while (content.front == '#' || content.front == '!') {
            parseComment(content);
        }
        // writefln("--content--\n%s\n----", content);
        if (!content.empty) {
            string key = parseKey(content);
            // writefln("Found key: %s", key);
            string value = parseValue(content);
            // writefln("Found value: %s", value);
            props[key] = value;
        }
    }
    return props;
}

private void parseComment(ref char[] content) {
    if (content.empty) return;
    dchar c = content.front;
    if (c == '#' || c == '!') {
        content.popFront; // Remove the comment char.
        while (c != '\n' && !content.empty) {
            c = content.front;
            content.popFront;
        }
    }
}

private string parseKey(ref char[] content) {
    dchar c = content.front;
    content.popFront;
    dchar[] keyChars = [c];
    bool keyFound = false;
    while (!keyFound) {
        if (content.empty) throw new Error("Unexpected end of file while parsing key.");
        c = content.front;
        content.popFront;
        // Detect the beginning of the separator.
        if (keyChars[$ - 1] != '\\' && (c == ' ' || c == '=' || c == ':')) {
            dchar separatorChar = ' ';
            if (c != ' ') separatorChar = c;
            while (c == ' ') {
                if (content.empty) throw new Error("Unexpected end of file while parsing separator.");
                c = content.front;
                if (c == ' ' || c == '=' || c == ':') {
                    content.popFront;
                    if (c == '=' || c == ':') break;
                }
            }
            // We have consumed as much whitespace as possible. If the separator char is a space, there's still the possibility to encounter a separator.
            if (separatorChar == ' ' && (c == '=' || c == ':')) {
                do {
                    if (content.empty)  throw new Error("Unexpected end of file while parsing separator trailing whitespace.");
                    c = content.front;
                    if (c == ' ') content.popFront;
                } while (c == ' ');
            }
            keyFound = true;
        } else if (keyChars[$ - 1] == '\\' && (c == ' ' || c == '=' || c == ':')) {
            keyChars[$ - 1] = c;
        } else {
            keyChars ~= c;
        }
    }
    return to!string(keyChars);
}

private string parseValue(ref char[] content) {
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
            if (content.empty) throw new Error("Unexpected end of file while parsing escape sequence.");
            dchar next = content.front;
            content.popFront;
            if (next == '\\') {
                valueChars ~= '\\';
            } else if (next == '\n') {
                do {
                    c = content.front;
                    if (c == ' ' || c == '\t') content.popFront;
                } while (c == ' ' || c == '\t');
            } else if (next == 'u') {
                valueChars ~= '\\';
                valueChars ~= 'u';
                for (int i = 0; i < 4; i++) {
                    if (content.empty || (!isAlphaNum(content.front))) throw new Error("Invalid unicode sequence.");
                    valueChars ~= content.front;
                    content.popFront;
                }
            } else {
                throw new Error("Unknown escape sequence: \"\\" ~ to!string(next) ~ "\"");
            }
        } else if (c == '\n') {
            valueFound = true;
        } else {
            valueChars ~= c;
        }
    }
    return to!string(valueChars);
}
