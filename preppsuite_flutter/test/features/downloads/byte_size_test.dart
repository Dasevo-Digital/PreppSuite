import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/byte_size.dart';

void main() {
  test('reads the way a mirror states a download', () {
    expect(formatByteSize(0), '0 B');
    expect(formatByteSize(999), '999 B');
    expect(formatByteSize(1000), '1.0 kB');
    expect(formatByteSize(159075814), '159 MB');
    // Wikipedia in German, complete, as the catalogue offers it.
    expect(formatByteSize(52392226816), '52 GB');
    expect(formatByteSize(14578860032), '15 GB');
    expect(formatByteSize(1400000000), '1.4 GB');
  });
}
