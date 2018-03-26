import 'package:test/test.dart';

import 'package:rencode/rencode.dart';

void main() {
  test('Test encoding', () {

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
    
    //Doubles


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
    expect(codec.decode([199, 12, 66, 63, 153, 153, 154, 130, 49, 50, 69, 67, 68, 103, 129, 97, 129, 98]), [12, 1.2, '12', null, true, false, {'a': 'b'}], skip: true); //floats are icky
    expect(codec.decode([108, 129, 97, 1, 129, 98, 130, 49, 50, 129, 99, 69, 129, 100, 67, 129, 101, 68, 129, 102, 195, 1, 2, 3]), {'a': 1, 'b': '12', 'c': null, 'd': true, 'e': false, 'f': [1, 2, 3]});
    expect(codec.decode([103, 129, 97, 196, 1, 2, 3, 103, 129, 98, 129, 99]), {'a': [1, 2, 3, {'b': 'c'}]});

    //Recursive list
    expect(codec.decode([194, 194, 194, 194, 195, 193, 1, 193, 2, 193, 3, 4, 5, 6, 7]), [[[[[[1], [2], [3]], 4], 5], 6], 7]);

    //Recursive map
    expect(codec.decode([103, 129, 97, 103, 129, 98, 104, 129, 99, 104, 129, 100, 129, 101, 129, 102, 129, 103, 129, 104, 103, 129, 105, 129, 106]), {'a': {'b': {'c': {'d': 'e', 'f': 'g'}, 'h': {'i': 'j'}}}});
    });
}

/*

*/