module d_properties;

public import d_properties.properties;
public import d_properties.writer;
public import d_properties.reader;

unittest {
    import std.format;
    import std.file;
    import std.stdio;

    // First test all valid cases.

    void readWriteValidTest(uint testCase) {
        string filename = format("test_cases/valid/%d.properties", testCase);
        string outFilename = format("test_cases/valid/%d-out.properties", testCase);
        auto p1 = Properties(filename);
        p1.writeToFile(outFilename);
        auto p2 = Properties(outFilename);
        remove(outFilename); // Remove the extra file now that we're done.
        assert(p1 == p2, "Properties are not equal after read/write cycle.");
    }

    readWriteValidTest(1);
    readWriteValidTest(2);

    // Test some specifics to ensure reading produces the expected values.
    auto p = Properties("test_cases/valid/2.properties");
    assert("my.value" in p);
    assert(p["my.value"] == "Hello world!");
    assert(p["another.value"] == "\"This is a quoted string\"");
    assert(p["This is an indented value"] == "12345");
    assert(p.get!int("This is an indented value") == 12_345);
    import std.conv : ConvException;
    try {
        p.get!char("This is an indented value");
        assert(false); // We expect an exception to be thrown.
    } catch (ConvException e) {
        // All good.
    }
    assert(p["multiline_2"] == "abc");
    assert("missing_key" !in p);
    assert(p.get("missing_key", "none") == "none");
    p["missing_key"] = "yes";
    assert("missing_key" in p);

    // Test property overwriting.
    p = Properties("test_cases/valid/2.properties", "test_cases/valid/3.properties");
    assert(p["my.value"] == "Goodbye world!");
    assert(p["another.value"] == "test");

    p = Properties("test_cases/valid/3.properties", "test_cases/valid/2.properties");
    assert(p["my.value"] == "Hello world!");
    assert(p["another.value"] == "\"This is a quoted string\"");

    p = Properties("test_cases/valid/2.properties");
    auto p2 = Properties("test_cases/valid/3.properties");
    p.addAll(p2);
    assert(p["my.value"] == "Goodbye world!");
    p.addAll("test_cases/valid/1.properties");
    assert("language" in p);

    // Test property subsets.
    p = Properties("test_cases/valid/subs.properties");
    auto one = p.getAll("one");
    assert(one["a"] == "1");
    assert(one["b"] == "2");
    assert(one["c"] == "3");
    assert(!one.has("name"));
    assert(!one.has("url"));
    auto two = p.getAll("two");
    assert(two["name"] == "Andrew");
    assert(two["url"] == "google.com");
    assert(!two.has("a"));
    assert(!two.has("b"));
    assert(!two.has("c"));

    struct TestOne {
        int a, b, c;
    }
    auto oneStruct = p.getAll!TestOne("one");
    assert(oneStruct.a == 1);
    assert(oneStruct.b == 2);
    assert(oneStruct.c == 3);

    // Then test all invalid cases, one-by-one, to check line number and/or message.

    try {
        readFromFile("test_cases/invalid/1.json");
    } catch (PropertiesParseException e) {
        assert(e.lineNumber == 1);
    }

    try {
        readFromFile("test_cases/invalid/2.properties");
    } catch (PropertiesParseException e) {
        assert(e.lineNumber == 2);
    }

    try {
        readFromFile("test_cases/invalid/3.properties");
    } catch (PropertiesParseException e) {
        assert(e.lineNumber == 3);
    }
}
