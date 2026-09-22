# Unicode 17.0.0 grapheme fixtures

Vendored, unmodified Unicode data, downloaded from:

- https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakProperty.txt
- https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt
- https://www.unicode.org/Public/17.0.0/ucd/DerivedCoreProperties.txt
- https://www.unicode.org/Public/17.0.0/ucd/auxiliary/GraphemeBreakTest.txt

See LICENSE.txt for the Unicode data license. The generator pins the SHA-256
of each input; regeneration is offline: `node Tools/generate-grapheme-data.mjs`.
It mechanically produces the Pascal property tables and all 766 official test
cases. Both compilers run the same scalar fixtures, converted to their respective
String encoding, and check exact resulting String offsets.

The implementation follows extended grapheme rules GB1–GB999 in
https://www.unicode.org/reports/tr29/tr29-47.html. Table lookup uses binary search;
segmentation is a forward pass with regional-indicator parity, Indic linker,
and emoji-ZWJ state. No runtime dependency or network access is required.

This conformance test validates segmentation only. Native IME interaction and
editor integration have separate tests and manual checks.
