# d-properties
D-language parser and serializer for Java-style properties files, which conforms to the [format specification on Wikipedia](https://en.wikipedia.org/wiki/.properties).

View this library on [code.dlang.org's package listing](https://code.dlang.org/packages/d-properties).

## Usage
Add this library to your project with `dub add d-properties`.

```d
import std.stdio;
import d_properties;

Properties props;

// Read properties from a file:
props = Properties("config.properties");
// Read from multiple files (values in subsequent files overwrite earlier ones):
props = Properties("base_config.properties", "extra.properties");
// Add properties from any additional file (or files):
props.addAll("another_file.properties");
props.addAll("yet_another.properties", "auxiliary.properties");
// Add properties from another Properties object:
Properties other = Properties(["key": "value"]);
props.addAll(other);

// Do stuff with the properties:
writeln(props); // Properties is a struct, so it can be converted to a string.
writeln(props["key"]); // Access property values via [].
props["key"] = "new value"; // Set a property like so.
writeln(props.get("unknown_key", "none")); // Get a property, or fallback to a default.

// Use the in operator to check if properties exist:
if ("unknown_key" in props) writeln("Property is present.");
if ("other_key" !in props) writeln("Property is not present.");

try {// Accessing missing properties with [] will throw MissingPropertyException
    writeln(props["unknown_key"]);
} catch (MissingPropertyException e) {
    writeln("Missing property!");
}

// Save to a file:
props.writeToFile("my_props.properties");
// Add a comment to the top of the file:
props.writeToFile("out.properties", "This is a comment");
// Use a different separator between keys and values (default is " = "):
props.writeToFile("out.properties", null, SeparatorStyle.COLON);
```
