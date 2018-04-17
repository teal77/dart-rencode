library rencode;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';

/*
* The bencode 'typecodes' such as i, d, etc have been extended and
* relocated on the base-256 character set.
*/
const int LIST = 59;
const int DICTIONARY = 60;
const int NUMBER = 61;
const int BYTE = 62;
const int SHORT = 63;
const int INT = 64;
const int LONG = 65;
const int FLOAT = 66;
const int DOUBLE = 44;
const int TRUE = 67;
const int FALSE = 68;
const int NULL = 69;
const int END = 127;
const int LENGTH_DELIM = 58;

//Positive integers with value embedded in typecode.
const int INT_POS_START = 0;
const int INT_POS_COUNT = 44;

//Negative integers with value embedded in typecode.
const int INT_NEG_START = 70;
const int INT_NEG_COUNT = 32;

//Dictionaries with length embedded in typecode.
const int DICT_START = 102;
const int DICT_COUNT = 25;

//Strings with length embedded in typecode.
const int STR_START = 128;
const int STR_COUNT = 64;

//Lists with length embedded in typecode.
const int LIST_START = STR_START + STR_COUNT;
const int LIST_COUNT = 64;

class RencodeCodec extends Codec<Object, List<int>> {
  @override
  Encoder get encoder {
    return new Encoder();
  }

  @override
  Decoder get decoder {
    return new Decoder();
  }
}

class Encoder extends Converter<Object, List<int>> {
  Queue<int> _output;

  @override
  List<int> convert(Object input) {
    _output = new ListQueue();
    _writeObject(input);
    return _output.toList();
  }

  void _writeObject(Object object) {
    if (object is Map) {
      _writeMap(object);
    } else if (object is Iterable) {
      _writeList(object);
    } else if (object is int) {
      _writeInt(object);
    } else if (object is double) {
      _writeDouble(object);
    } else if (object is BigInt) {
      _writeBigint(object);
    } else if (object is bool) {
      _writeBool(object);
    } else if (object == null) {
      _writeNull();
    } else if (object is String) {
      _writeString(object);
    } else {
      throw new ArgumentError("Object of type ${object.runtimeType.toString()} is not supported");
    }
  }

  void _writeMap(Map<Object, Object> map) {
    if (map.length < DICT_COUNT) {
      _output.add(DICT_START + map.length);
      map.forEach((k, v) {
        _writeObject(k);
        _writeObject(v);
      });
    } else {
      _output.add(DICTIONARY);
      map.forEach((k, v) {
        _writeObject(k);
        _writeObject(v);
      });
      _output.add(END);
    }
  }

  void _writeList(Iterable<Object> iterable) {
    int length = iterable.length;
    if (length < LIST_COUNT) {
      _output.add(LIST_START + length);
      iterable.forEach((o) => _writeObject(o));
    } else {
      _output.add(LIST);
      iterable.forEach((o) => _writeObject(o));
      _output.add(END);
    }
  }

  void _writeInt(int i) {
    if (i >= 0 && i < INT_POS_COUNT) {
      _output.add(INT_POS_START + i);
    } else if (i >= -INT_NEG_COUNT && i < 0) {
      _output.add(INT_NEG_START - 1 - i);
    } else if (i >= -128 && i < 128) {
      ByteData b = new ByteData(1);
      b.setUint8(0, i);
      _output.add(BYTE);
      _output.addAll(b.buffer.asUint8List());
    } else if (i >= -32768 && i < 32768) {
      ByteData b = new ByteData(2);
      b.setUint16(0, i);
      _output.add(SHORT);
      _output.addAll(b.buffer.asUint8List());
    } else if (i >= -2147483648 && i < 2147483648) {
      ByteData b = new ByteData(4);
      b.setUint32(0, i);
      _output.add(INT);
      _output.addAll(b.buffer.asUint8List());
    } else if (i >= -9223372036854775808 && i <= 9223372036854775807) {
      ByteData b = new ByteData(8);
      b.setUint64(0, i);
      _output.add(LONG);
      _output.addAll(b.buffer.asUint8List());
    } else {
      _writeBigint(new BigInt.from(i));
    }
  }

  void _writeDouble(double d) {
    ByteData b = new ByteData(8);
    b.setFloat64(0, d);
    _output.add(DOUBLE);
    _output.addAll(b.buffer.asUint8List());
  }

  void _writeBigint(BigInt b) {
    _output.add(NUMBER);
    _output.addAll(utf8.encode(b.toString()));
    _output.add(END);
  }

  void _writeBool(bool b) {
    _output.add(b ? TRUE : FALSE);
  }

  void _writeNull() {
    _output.add(NULL);
  }

  void _writeString(String s) {
    List<int> utf8String = utf8.encode(s);
    if (utf8String.length < STR_COUNT) {
      _output.add(STR_START + utf8String.length);
      _output.addAll(utf8String);
    } else {
      String lengthStr = utf8String.length.toString();
      _output.addAll(utf8.encode(lengthStr));
      _output.add(LENGTH_DELIM);
      _output.addAll(utf8String);
    }
  }
}

class Decoder extends Converter<List<int>, Object> {
  Queue<int> _input;

  @override
  Object convert(List<int> input) {
    this._input = new ListQueue.from(input);
    return _readObject();
  }

  void _removeMany(int n) {
    for (int i = 0; i < n; i++) {
      _input.removeFirst();
    }
  }

  Object _readObject() {
    var token = _input.first;
    if (isMap(token) || isFixedMap(token)) {
      return _readMap();
    } else if (isList(token) || isFixedList(token)) {
      return _readList();
    } else if (isInt(token) || isEmbeddedPositiveInt(token) || isEmbeddedNegativeInt(token)) {
      return _readInt();
    } else if (isDouble(token)) {
      return _readDouble();
    } else if (isNumber(token)) {
      return _readNumber();
    } else if (isBool(token)) {
      return _readBool();
    } else if (token == NULL) {
      _input.removeFirst();
      return null;
    } else {
      return _readStringOrBytes();
    }
  }

  bool isMap(int typeCode) {
    return typeCode == DICTIONARY;
  }

  bool isFixedMap(int typeCode) {
    return typeCode >= DICT_START && typeCode < (DICT_START + DICT_COUNT);
  }

  bool isList(int typeCode) {
    return typeCode == LIST;
  }

  bool isFixedList(int typeCode) {
    return typeCode >= LIST_START && typeCode < (LIST_START + LIST_COUNT);
  }

  bool isInt(int typeCode) {
    return typeCode == BYTE || typeCode == SHORT || typeCode == INT || typeCode == LONG;
  }

  bool isEmbeddedPositiveInt(int typeCode) {
    return typeCode >= INT_POS_START && typeCode < (INT_POS_START + INT_POS_COUNT);
  }

  bool isEmbeddedNegativeInt(int typeCode) {
    return typeCode >= INT_NEG_START && typeCode < (INT_NEG_START + INT_NEG_COUNT);
  }

  bool isDouble(int typeCode) {
    return typeCode == FLOAT || typeCode == DOUBLE;
  }

  bool isNumber(int typeCode) {
    return typeCode == NUMBER;
  }

  bool isBool(int typeCode) {
    return typeCode == TRUE || typeCode == FALSE;
  }

  bool isFixedString(int typeCode) {
    return typeCode >= STR_START && typeCode < (STR_START + STR_COUNT);
  }

  Map<Object, Object> _readMap() {
    var token = _input.removeFirst();

    var map = <Object, Object>{};
    if (isFixedMap(token)) {
      var length = token - DICT_START;
      for (int i = 0; i < length; i++) {
        var key = _readObject();
        var value = _readObject();
        map[key] = value;
      }
    } else {
      while (_input.first != END) {
        var key = _readObject();
        var value = _readObject();
        map[key] = value;
      }
      _input.removeFirst();
    }

    return map;
  }

  List<Object> _readList() {
    var token = _input.removeFirst();

    var list = <Object>[];
    if (isFixedList(token)) {
      var length = token - LIST_START;
      for (int i = 0; i < length; i++) {
        list.add(_readObject());
      }
    } else {
      while (_input.first != END) {
        list.add(_readObject());
      }
      _input.removeFirst();
    }

    return list;
  }

  int _readInt() {
    var token = _input.removeFirst();

    if (isEmbeddedPositiveInt(token)) {
      return INT_POS_START + token;
    } else if (isEmbeddedNegativeInt(token)) {
      return INT_NEG_START - 1 - token;
    } else {
      var i = 0;
      if (token == BYTE) {
        var list = new Uint8List.fromList(_input.take(1).toList());
        i = list.buffer.asByteData().getInt8(0);
        _removeMany(1);
      } else if (token == SHORT) {
        var list = new Uint8List.fromList(_input.take(2).toList());
        i = list.buffer.asByteData().getInt16(0);
        _removeMany(2);
      } else if (token == INT) {
        var list = new Uint8List.fromList(_input.take(4).toList());
        i = list.buffer.asByteData().getInt32(0);
        _removeMany(4);
      } else if (token == LONG) {
        var list = new Uint8List.fromList(_input.take(8).toList());
        i = list.buffer.asByteData().getInt64(0);
        _removeMany(8);
      }
      return i;
    }
  }

  double _readDouble() {
    var token = _input.removeFirst();

    var d = 0.0;
    if (token == FLOAT) {
      var list = new Uint8List.fromList(_input.take(4).toList());
      d = list.buffer.asByteData().getFloat32(0);
      _removeMany(4);
    } else if (token == DOUBLE) {
      var list = new Uint8List.fromList(_input.take(8).toList());
      d = list.buffer.asByteData().getFloat64(0);
      _removeMany(8);
    }
    return d;
  }

  Object _readNumber() {
    _input.removeFirst();

    var num = _input.takeWhile((i) => i != END).toList();
    var numStr = utf8.decode(num);

    _removeMany(num.length + 1);

    if (numStr.contains('.')) {
      return double.parse(numStr);
    } else {
      return BigInt.parse(numStr);
    }
  }

  bool _readBool() {
    var token = _input.removeFirst();
    if (token == TRUE) {
      return true;
    } else {
      return false;
    }
  }

  Object _readStringOrBytes() {
    var bytes = _readByteString();
    try {
      return utf8.decode(bytes);
    } catch (FormatException) {
      return bytes;
    }
  }

  List<int> _readByteString() {
    var token = _input.first;

    if (isFixedString(token)) {
      _input.removeFirst();
      var length = token - STR_START;
      var bytes = _input.take(length).toList();
      _removeMany(length);
      return bytes;

    } else if (token >= '1'.codeUnitAt(0) && token <= '9'.codeUnitAt(0)) {
      var length = _input.takeWhile((i) => i != LENGTH_DELIM).toList();
      var lengthStr = utf8.decode(length);
      var lengthInt = int.parse(lengthStr);

      _removeMany(length.length + 1);

      var bytes = _input.take(lengthInt).toList();
      _removeMany(lengthInt);
      return bytes;
    } else {
      throw new FormatException("Malformed rencode ", _input);
    }
  }
}