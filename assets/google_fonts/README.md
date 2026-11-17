# Bundled fonts

Noto Serif Thai, IBM Plex Sans Thai and IBM Plex Mono, all licensed under the
SIL Open Font License 1.1 (https://openfontlicense.org).

Files are the exact static instances the `google_fonts` package would download
(SHA-256 verified against the hashes in the package), named the way it expects
(`<Family>-<Weight>.ttf`) so it uses them offline. Only the weights the app
uses are included; any other weight falls back to a runtime download.
