module d_properties.properties;

import object : Error;
import d_properties.reader;
import d_properties.writer;

/** 
 * The properties is a struct containing key-value pairs of strings, which can
 * be easily and efficiently written to and read from a file.
 */
public struct Properties {
    /** 
     * The internal values of this properties struct.
     */
    public string[string] values;

    /** 
     * Constructs a Properties from the given values.
     * Params:
     *   valueMap = The associative array of properties.
     */
    public this(string[string] valueMap) {
        foreach (key, value; valueMap) {
            this.opIndexAssign(value, key);
        }
    }

    /** 
     * Constructs a Properties by reading from each of the given files, in the
     * order that they're provided. Note that properties in an earlier file
     * will be overwritten by properties of the same key in later files.
     * Params:
     *   filenames = The list of filenames.
     */
    public this(string[] filenames ...) {
        foreach (filename; filenames) {
            Properties p = readFromFile(filename);
            this.addAll(p);
        }
    }

    /** 
     * Gets the value of a property, or returns the specified default value if
     * the given property doesn't exist.
     * Params:
     *   key = The property name.
     *   defaultValue = The default value to use, if no property exists.
     * Returns: The value of the property, or the default value if the property
     * doesn't exist.
     */
    public string get(string key, string defaultValue=null) {
        if (key !in values) return defaultValue;
        return values[key];
    }

    /** 
     * Adds all properties from the given Properties to this one, overwriting
     * any properties with the same name.
     * Params:
     *   properties = The properties to add to this one.
     */
    public void addAll(Properties[] properties ...) {
        foreach (p; properties) {
            foreach (key, value; p.values) {
                this.values[key] = value;
            }
        }
    }

    /** 
     * Adds all properties from the given files to this one.
     * Params:
     *   filenames = The names of files to read properties from.
     */
    public void addAll(string[] filenames ...) {
        auto p = Properties(filenames);
        this.addAll(p);
    }

    /** 
     * Gets the value of a property, or throws a missing property exception.
     * Params:
     *   key = The property name.
     * Returns: The value of the property.
     */
    string opIndex(string key) {
        if (key !in values) throw new MissingPropertyException(key);
        return values[key];
    }

    /** 
     * Assigns the given value to a property.
     * Params:
     *   value = The value of the property.
     *   key = The property name.
     */
    void opIndexAssign(string value, string key) {
        values[key] = value;
    }

    bool opEquals(Properties other) {
        return this.values == other.values;
    }

    bool opBinaryRight(string op)(string key) const if (op == "in") {
        return (key in this.values) != null;
    }
}

/** 
 * Exception that's thrown when attempting to index an unknown key.
 */
class MissingPropertyException : Error {
    this(string missingKey) {
        super("Missing value for key \"" ~ missingKey ~ "\".");
    }
}