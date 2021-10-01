import std.stdio;

import d_properties;

void main()
{
	auto p = readFromFile("test_cases/valid/2.properties");
	writeln(p);
	p = readFromFile("test_cases/valid/1.properties");
	p.writeToFile("test_cases/valid/1-out.properties");

	p = Properties("test.properties", "test_cases/valid/1.properties");
	p.writeToFile("test1.properties");
}
