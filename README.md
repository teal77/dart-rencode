# dart-rencode

Rencoding implementation in dart.

Rencoding is a more complicated version of [bencoding](https://en.wikipedia.org/wiki/Bencode) used by the Deluge torrent client and its RPC APIS.

It produces smaller encoding for small inputs than the original bencode.

**Note**

You probably don't need this unless you are writing a Deluge RPC client.
