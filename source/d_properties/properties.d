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
     * Checks if the given property exists within this set.
     * Params:
     *   key = The property name.
     * Returns: True if the property exists.
     */
    public bool has(string key) {
        return cast(bool) (key in values);
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
    public string get(string key, string defaultValue=null) const {
        if (key !in values) return defaultValue;
        return values[key];
    }

    /** 
     * Gets a property's value as a certain type. If the property does not
     * exist, a `MissingPropertyException` is thrown. If the conversion could
     * not be performed, a `std.conv.ConvException` is thrown.
     * Params:
     *   key = The property name.
     * Returns: The value of the property.
     */
    public T get(T)(string key) const {
        import std.conv : to;
        if (key !in values) throw new MissingPropertyException(key);
        return to!(T)(values[key]);
    }

    /** 
     * Gets a property's value as a certain type. If the property does not
     * exist, a default value is returned. If the conversion could not be
     * performed, a `std.conv.ConvException` is thrown.
     * Params:
     *   key = The property name.
     *   defaultValue = The default value to use, if no property exists.
     * Returns: The value of the property, or the default value if the property
     * doesn't exist.
     */
    public T get(T)(string key, T defaultValue) const {
        import std.conv : to;
        if (key !in values) return defaultValue;
        return to!(T)(values[key]);
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
     * Gets a new set of properties containing only those whose names match
     * the given prefix. Note that if you use `.` as a separator between the
     * prefix and sub-properties, it will be removed. For example, `getAll("a")`
     * would return a property named `"b"` instead of `".b"`, assuming a full
     * name of `"a.b"`.
     * Params:
     *   prefix = The prefix to get properties for.
     * Returns: A new properties containing any properties that match the given
     * prefix.
     */
    public Properties getAll(string prefix) {
        import std.algorithm : startsWith;
        Properties p;
        foreach (name, value; this.values) {
            if (name.startsWith(prefix) && name.length > prefix.length) {
                size_t idx = prefix.length;
                if (name[idx] == '.' && name.length > prefix.length + 1) idx++;
                p[name[idx .. $]] = value;
            }
        }
        return p;
    }

    /** 
     * Gets a set of properties whose names match the given prefix, and uses
     * them to populate a struct of the given type.
     * Params:
     *   prefix = The prefix to get properties for.
     * Returns: An instance of the given struct type.
     */
    public T getAll(T)(string prefix) {
        return getAll(prefix).as!T;
    }

    /** 
     * Converts this set of properties into the given struct type, matching
     * any properties to their equivalent members in the struct. Note that you
     * must ensure that all members may be converted from a `string` using
     * `std.conv.to`.
     * Returns: An instance of the given struct type.
     */
    public T as(T)() {
        static if (!__traits(isPOD, T)) {
            assert(0, "Only Plain Old Data structs may be used to get all.");
        }
        import std.traits;
        import std.conv : to;
        T t;
        foreach (member; __traits(allMembers, T)) {
            if (this.has(member)) {// TODO: Better name inference.
                alias membertype = typeof(mixin("T()."~member));
                __traits(getMember, t, member) = to!(membertype)(this.values[member]);
            }
        }
        return t;
    }

    /** 
     * Gets the value of a property, or throws a missing property exception.
     * Params:
     *   key = The property name.
     * Returns: The value of the property.
     */
    string opIndex(string key) const {
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

    /** 
     * Determines if this properties object is equal to the other.
     * Params:
     *   other = The other properties to check for equality with.
     * Returns: True if these properties are the same as those given.
     */
    bool opEquals(const Properties other) const {
        return this.values == other.values;
    }

    /** 
     * Implementation of the binary "in" operator to determine if a property is
     * defined for this properties object.
     * Params:
     *   key = The name of a property.
     * Returns: True if the property exists in this properties object.
     */
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