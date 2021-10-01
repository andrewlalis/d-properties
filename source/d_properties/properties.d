module d_properties.properties;

import object : Error;
import d_properties.reader;
import d_properties.writer;

struct Properties {
    string[string] values;

    this(string[string] valueMap) {
        foreach (key, value; valueMap) {
            this.opIndexAssign(value, key);
        }
    }

    this(string[] filenames ...) {
        foreach (filename; filenames) {
            Properties p = readFromFile(filename);
            this.addAll(p);
        }
    }

    string get(string key, string defaultValue=null) {
        if (key !in values) return defaultValue;
        return values[key];
    }

    void addAll(Properties other) {
        foreach (key, value; other.values) {
            this.values[key] = value;
        }
    }

    string opIndex(string key) {
        if (key !in values) throw new MissingPropertyException(key);
        return values[key];
    }

    void opIndexAssign(string value, string key) {
        values[key] = value;
    }

    bool opEquals(Properties other) {
        return this.values == other.values;
    }
}

class MissingPropertyException : Error {
    public string missingKey;

    this(string missingKey) {
        super("Missing value for key \"" ~ missingKey ~ "\".");
        this.missingKey = missingKey;
    }
}