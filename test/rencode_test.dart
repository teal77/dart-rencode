import 'dart:math';

import 'package:test/test.dart';

import 'package:rencode/rencode.dart';

void main() {
  test('Test encoding', () {
    //All the hardcoded arrays are output of original python rencode implementation

    RencodeCodec codec = new RencodeCodec();

    //Positive embedded ints
    expect(codec.encode(0), [0]);
    expect(codec.encode(43), [43]);

    //Negative embedded ints
    expect(codec.encode(-1), [70]);
    expect(codec.encode(-32), [101]);

    //Bytes
    expect(codec.encode(44), [62, 44]);
    expect(codec.encode(127), [62, 127]);
    expect(codec.encode(-33), [62, 223]);
    expect(codec.encode(-128), [62, 128]);

    //Shorts
    expect(codec.encode(128), [63, 0, 128]);
    expect(codec.encode(32767), [63, 127, 255]);
    expect(codec.encode(-129), [63, 255, 127]);
    expect(codec.encode(-32768), [63, 128, 0]);

    //Ints
    expect(codec.encode(32768), [64, 0, 0, 128, 0]);
    expect(codec.encode(2147483647), [64, 127, 255, 255, 255]);
    expect(codec.encode(-32769), [64, 255, 255, 127, 255]);
    expect(codec.encode(-2147483648), [64, 128, 0, 0, 0]);

    //Longs
    expect(codec.encode(2147483648), [65, 0, 0, 0, 0, 128, 0, 0, 0]);
    expect(codec.encode(9223372036854775807), [65, 127, 255, 255, 255, 255, 255, 255, 255]);
    expect(codec.encode(-2147483649), [65, 255, 255, 255, 255, 127, 255, 255, 255]);
    expect(codec.encode(-9223372036854775808), [65, 128, 0, 0, 0, 0, 0, 0, 0]);

    //Numbers
    expect(codec.encode(BigInt.parse("9223372036854775808")), [NUMBER]..addAll("9223372036854775808".codeUnits)..add(END));

    //Null
    expect(codec.encode(null), [NULL]);

    //Bools
    expect(codec.encode(true), [TRUE]);
    expect(codec.encode(false), [FALSE]);

    //Fixed map
    expect(codec.encode({'a' : 'b'}), [103, 129, 97, 129, 98]);
    expect(codec.encode({'a' : 1, 'b' : 2, '3' : 3}), [105, 129, 97, 1, 129, 98, 2, 129, 51, 3]);

    //Fixed list
    expect(codec.encode(['a','b','b']), [195, 129, 97, 129, 98, 129, 98]);
    expect(codec.encode([1,2,3,4]), [196, 1, 2, 3, 4]);

    //Strings
    expect(codec.encode("abcdefgh"), [136, 97, 98, 99, 100, 101, 102, 103, 104]);
    expect(codec.decode([57, 49, 58, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
    111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
    48, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 45, 61, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
    75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123, 125, 91, 93, 58, 59, 34, 39,
    44, 46, 60, 62, 63, 47]), "abcdefghijklmnopqrstuvwxyz01234567890!@#\$%^&*()_+-=ABCDEFGHIJKLMNOPQRSTUVWXYZ{}[]:;\"',.<>?/");

    //Random stuff
    expect(codec.encode({'a': 1, 'b': '12', 'c': null, 'd': true, 'e': false, 'f': [1, 2, 3]}), [108, 129, 97, 1, 129, 98, 130, 49, 50, 129, 99, 69, 129, 100, 67, 129, 101, 68, 129, 102, 195, 1, 2, 3]);
    expect(codec.encode({'a': [1, 2, 3, {'b': 'c'}]}), [103, 129, 97, 196, 1, 2, 3, 103, 129, 98, 129, 99]);

    //Recursive list
    expect(codec.encode([[[[[[1], [2], [3]], 4], 5], 6], 7]), [194, 194, 194, 194, 195, 193, 1, 193, 2, 193, 3, 4, 5, 6, 7]);

    //Recursive map
    expect(codec.encode({'a': {'b': {'c': {'d': 'e', 'f': 'g'}, 'h': {'i': 'j'}}}}), [103, 129, 97, 103, 129, 98, 104, 129, 99, 104, 129, 100, 129, 101, 129, 102, 129, 103, 129, 104, 103, 129, 105, 129, 106]);
  });

  test('Test decoding', () {
    //All the hardcoded arrays are output of original python rencode implementation

    RencodeCodec codec = new RencodeCodec();

    //Positive embedded ints
    expect(codec.decode([0]), 0);
    expect(codec.decode([43]), 43);

    //Negative embedded ints
    expect(codec.decode([70]), -1);
    expect(codec.decode([101]), -32);

    //Bytes
    expect(codec.decode([62, 44]), 44);
    expect(codec.decode([62, 127]), 127);
    expect(codec.decode([62, 223]), -33);
    expect(codec.decode([62, 128]), -128);

    //Shorts
    expect(codec.decode([63, 0, 128]), 128);
    expect(codec.decode([63, 127, 255]), 32767);
    expect(codec.decode([63, 255, 127]), -129);
    expect(codec.decode([63, 128, 0]), -32768);

    //Ints
    expect(codec.decode([64, 0, 0, 128, 0]), 32768);
    expect(codec.decode([64, 127, 255, 255, 255]), 2147483647);
    expect(codec.decode([64, 255, 255, 127, 255]), -32769);
    expect(codec.decode([64, 128, 0, 0, 0]), -2147483648);

    //Longs
    expect(codec.decode([65, 0, 0, 0, 0, 128, 0, 0, 0]), 2147483648);
    expect(codec.decode([65, 127, 255, 255, 255, 255, 255, 255, 255]), 9223372036854775807);
    expect(codec.decode([65, 255, 255, 255, 255, 127, 255, 255, 255]), -2147483649);
    expect(codec.decode([65, 128, 0, 0, 0, 0, 0, 0, 0]), -9223372036854775808);

    //Numbers
    expect(codec.decode([NUMBER]..addAll("9223372036854775808".codeUnits)..add(END)), BigInt.parse("9223372036854775808"));
    expect(codec.decode([NUMBER]..addAll("9.223372036854775808".codeUnits)..add(END)), 9.223372036854775808);

    //Null
    expect(codec.decode([NULL]), null);

    //Bools
    expect(codec.decode([TRUE]), true);
    expect(codec.decode([FALSE]), false);

    //Fixed map
    expect(codec.decode([103, 129, 97, 129, 98]), {'a' : 'b'});
    expect(codec.decode([105, 129, 97, 1, 129, 98, 2, 129, 51, 3]), {'a' : 1, 'b' : 2, '3' : 3});

    //Fixed list
    expect(codec.decode([195, 129, 97, 129, 98, 129, 98]), ['a','b','b']);
    expect(codec.decode([196, 1, 2, 3, 4]), [1,2,3,4]);

    //Strings
    expect(codec.decode([136, 97, 98, 99, 100, 101, 102, 103, 104]), "abcdefgh");
    expect(codec.decode([57, 49, 58, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110,
    111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57,
    48, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 45, 61, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
    75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 123, 125, 91, 93, 58, 59, 34, 39,
    44, 46, 60, 62, 63, 47]), "abcdefghijklmnopqrstuvwxyz01234567890!@#\$%^&*()_+-=ABCDEFGHIJKLMNOPQRSTUVWXYZ{}[]:;\"',.<>?/");

    //Random stuff
    expect(codec.decode([108, 129, 97, 1, 129, 98, 130, 49, 50, 129, 99, 69, 129, 100, 67, 129, 101, 68, 129, 102, 195, 1, 2, 3]), {'a': 1, 'b': '12', 'c': null, 'd': true, 'e': false, 'f': [1, 2, 3]});
    expect(codec.decode([103, 129, 97, 196, 1, 2, 3, 103, 129, 98, 129, 99]), {'a': [1, 2, 3, {'b': 'c'}]});

    //Recursive list
    expect(codec.decode([194, 194, 194, 194, 195, 193, 1, 193, 2, 193, 3, 4, 5, 6, 7]), [[[[[[1], [2], [3]], 4], 5], 6], 7]);

    //Recursive map
    expect(codec.decode([103, 129, 97, 103, 129, 98, 104, 129, 99, 104, 129, 100, 129, 101, 129, 102, 129, 103, 129, 104, 103, 129, 105, 129, 106]), {'a': {'b': {'c': {'d': 'e', 'f': 'g'}, 'h': {'i': 'j'}}}});
    });

  test('Test both', () {
    RencodeCodec codec = new RencodeCodec();

    expect(codec.decode(codec.encode(1.2345)), 1.2345);
    expect(codec.decode(codec.encode(1234567890123456789)), 1234567890123456789);
    expect(codec.decode(codec.encode(1234567890123456789.1234567890)), 1234567890123456789.1234567890);

    Object ld = [[{'a' : 15, 'bb' : 2.5, 'ccc' : 29.3, '' : [-0.3, <int>[], false, true, '']},
        ['a', 10e20],]..addAll(new Iterable.generate(100000)), pow(2, 30), pow(2, 33), pow(2, 60), pow(2, 66),
        'b' * 30, 'v' * 33, 'c' * 64, pow(2, 1000), false, true, false, -1, 0, 1];

    expect(codec.decode(codec.encode(ld)), ld);

    ld = ['', 'a'*10, 'b'*100, 'c'*1000, 'd'*10000, 'd'*(10^5), 'e'*(10^6), 'f'*(10^7)];

    expect(codec.decode(codec.encode(ld)), ld);

    expect(codec.decode(codec.encode("ಠ_ಠ")), "ಠ_ಠ");
  });
}