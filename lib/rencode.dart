library rencode;

import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';

/* The bencode 'typecodes' such as i, d, etc have been extended and
    relocated on the base-256 character set. */
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

//Negative integers with value embedded in typecode..
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
  @override
  List<int> convert(Object input) {

  }
}

class Decoder extends Converter<List<int>, Object> {
  Queue<int> _input;

  @override
  Object convert(List<int> input) {
    this._input = new ListQueue.from(input);
    return _readObject();
  }

  Queue _removeMany(int n) {
    return new ListQueue.from(_input.skip(n));
  }

  Object _readObject() {
    int token = _input.first;
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

  Map<String, Object> _readMap() {
    int token = _input.removeFirst();

    Map<String, Object> map = new Map();
    if (isFixedMap(token)) {
      int length = token - DICT_START;
      for (int i = 0; i < length; i++) {
        String key = _readString();
        Object value = _readObject();
        map[key] = value;
      }
    } else {
      while (_input.first != END) {
        String key = _readString();
        Object value = _readObject();
        map.putIfAbsent(key, value);
      }
      _input.removeFirst();
    }

    return map;
  }

  List<Object> _readList() {
    int token = _input.removeFirst();

    List<Object> list = new List();
    if (isFixedList(token)) {
      int length = token - LIST_START;
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

  String _readString() {
    List<int> bytes = _readByteString();
    return UTF8.decode(bytes);
  }

  int _readInt() {
    int token = _input.removeFirst();

    if (isEmbeddedPositiveInt(token)) {
      return INT_POS_START + token;
    } else if (isEmbeddedNegativeInt(token)) {
      return INT_NEG_START - 1 - token;
    } else {
      int i = 0;
      if (token == BYTE) {
        Uint8List list = new Uint8List.fromList(_input.take(1).toList());
        i = list.buffer.asByteData().getInt8(0);
        _input = _removeMany(1);
      } else if (token == SHORT) {
        Uint8List list = new Uint8List.fromList(_input.take(2).toList());
        i = list.buffer.asByteData().getInt16(0);
        _input = _removeMany(2);
      } else if (token == INT) {
        Uint8List list = new Uint8List.fromList(_input.take(4).toList());
        i = list.buffer.asByteData().getInt32(0);
        _input = _removeMany(4);
      } else if (token == LONG) {
        Uint8List list = new Uint8List.fromList(_input.take(8).toList());
        i = list.buffer.asByteData().getInt64(0);
        _input = _removeMany(8);
      }
      return i;
    }
  }

  double _readDouble() {
    int token = _input.removeFirst();

    double d = 0.0;
    if (token == FLOAT) {
      Uint8List list = new Uint8List.fromList(_input.take(4).toList());
      d = list.buffer.asByteData().getFloat32(0);
      _input = _removeMany(4);
    } else if (token == DOUBLE) {
      Uint8List list = new Uint8List.fromList(_input.take(8).toList());
      d = list.buffer.asByteData().getFloat64(0);
      _input = _removeMany(8);
    }
    return d;
  }

  Object _readNumber() {
    _input.removeFirst();

    List<int> num = _input.takeWhile((i) => i != END).toList();
    String numStr = UTF8.decode(num);

    _input = _removeMany(num.length);
    _input.removeFirst();

    if (numStr.contains('.')) {
      return double.parse(numStr);
    } else {
      return BigInt.parse(numStr);
    }
  }

  bool _readBool() {
    int token = _input.removeFirst();
    if (token == TRUE) {
      return true;
    } else {
      return false;
    }
  }

  Object _readStringOrBytes() {
    List<int> bytes = _readByteString();
    try {
      return UTF8.decode(bytes);
    } catch (FormatException) {
      return bytes;
    }
  }

  List<int> _readByteString() {
    int token = _input.first;

    if (isFixedString(token)) {
      _input.removeFirst();
      int length = token - STR_START;
      List<int> bytes = _input.take(length).toList();
      _input = _removeMany(length);
      return bytes;

    } else if (token >= '1'.codeUnitAt(0) && token <= '9'.codeUnitAt(0)) {
      List<int> length = _input.takeWhile((i) => i != LENGTH_DELIM).toList();
      String lengthStr = UTF8.decode(length);
      int lengthInt = int.parse(lengthStr);

      _input = _removeMany(length.length);
      _input.removeFirst();

      List<int> bytes = _input.take(lengthInt).toList();
      _input = _removeMany(lengthInt);
      return bytes;
    } else {
      throw new FormatException("Malformed rencode ", _input);
    }
  }
}

