# News

## 3.2.0 - 2025-12-17

### Improvements

  * Improved documents.
    * GH-179
    * GH-188
    * GH-189
    * GH-190
    * GH-191
    * GH-192
    * GH-193
    * GH-194
    * Patch by Burdette Lamar

### Thanks

  * Burdette Lamar

## 3.1.9 - 2025-12-01

### Improvements

  * [DOC] Tweaks for StringIO#each_line
    * GH-165

  * [DOC] Doc for StringIO.size
    * GH-175

  * [DOC] Tweaks for StringIO#fsync
    * GH-173

  * [DOC] Fix #seek link
    * GH-174

  * Add a note about chilled string support to 3.1.8 release note
    * GH-180 fixes GH-179

### Fixes

  * JRuby: Removed use of RubyBasicObject.flags
    * GH-182

### Thanks

  * Burdette Lamar

  * Charles Oliver Nutter

## 3.1.8 - 2025-11-12

### Improvements

  * Improved documents
    * Patch by Burdette Lamar

  * Improved chilled string support
    * GH-128

### Fixes

  * Fixed SEGV in `StringIO#seek` with `SEEK_END` on `StringIO.new(nil)`
    * GH-137
    * Patch by koh-sh

  * Fixed SEGV in `StringIO#read` on `StringIO.new(nil)`

  * Fixed SEGV in `StringIO#pread` on `StringIO.new(nil)`

  * Fixed SEGV in `StringIO#eof?` on `StringIO.new(nil)`

  * JRuby: Fixed a bug that `StringIO#read` doesn't clear code range
    * GH-156
    * Patch by Karol Bucek

### Thanks

  * koh-sh

  * Burdette Lamar

  * Karol Bucek

## 3.1.7 - 2025-04-21

### Improvements

  * CRuby: Added support for `rb_io_mode_t` that will be introduced in
    Ruby 3.5 or later.
    * GH-129
    * Patch by Samuel Williams

### Thanks

  * Samuel Williams

## 3.1.6 - 2025-03-25

### Fixes

  * CRuby: Fix SEGV at unget to a null device StringIO
  * JRuby:
    * Fix NullPointerException at unget to a null device StringIO
    * Use proper checkEncoding signature
    * Update strioWrite logic to match CRuby
    * GH-124

## 3.1.5 - 2025-02-21

### Improvements

  * JRuby: Improved compatibility with CRuby for `StringIO#seek` with
    frozen string.
    * GH-119
    * GH-121

## 3.1.4 - 2025-02-20

### Improvements

  * JRuby: Improved compatibility with CRuby.
    * GH-116

### Fixes

  * CRuby: Fixed a bug that `StringIO` may mutate a shared string.
    * GH-117

## 3.1.3 - 2025-02-14

### Fixes

  * JRuby: Fixed a bug that JRuby may not be able to be started
    * GH-112
    * GH-113
    * Reported by Karol Bucek

### Thanks

  * Karol Bucek

## 3.1.2 - 2024-11-07

### Improvements

  * JRuby: Added support for detecting encoding by BOM.
    * GH-100
    * GH-101

### Fixes

  * CRuby: Fixed a bug that unknown memory may be used by
    `StringIO#ungetc`/`StringIO#ungetbyte`.
    * https://hackerone.com/reports/2805165
    * Reported by manun.

### Thanks

  * manun

## 3.1.1 - 2024-06-13

### Improvements

  * JRuby: Improved.
    * GH-83
    * GH-84
    * GH-85

  * Added `StringIO::MAX_LENGTH`.

  * Added support for NULL `StringIO` by `StringIO.new(nil)`.

  * Improved IO compatibility for partial read.
    * GH-95
    * https://bugs.ruby-lang.org/issues/20418

### Fixes

  * Fixed a bug that coderange isn't updated after overwrite.
    * Reported by Tiago Cardoso.
    * https://bugs.ruby-lang.org/issues/20185
    * GH-77
    * GH-79

### Thanks

  * Tiago Cardoso

## 3.1.0 - 2023-11-28

### Fixes

  * TruffleRuby: Do not compile the C extension

    GH-71

## 3.0.9 - 2023-11-08

### Improvements

  * JRuby: Aligned `StringIO#gets` behavior with the C implementation.

    GH-61

### Fixes

  * CRuby: Fixed `StringIO#pread` with the length 0.

    Patch by Jean byroot Boussier.

    GH-67

  * CRuby: Fixed a bug that `StringIO#gets` with non ASCII compatible
    encoding such as UTF-16 doesn't detect correct new line characters.

    Reported by IWAMOTO Kouichi.

    GH-68

### Thanks

  * Jean byroot Boussier

  * IWAMOTO Kouichi

## 3.0.8 - 2023-08-10

### Improvements

  * Added `StringIO#pread`.

    Patch by Jean byroot Boussier.

    GH-56

  * JRuby: Added `StringIO::VERSION`.

    GH-57 GH-59

### Thanks

  * Jean byroot Boussier

## 3.0.7 - 2023-06-02

  * CRuby: Avoid direct struct usage. This change is for supporting
    Ruby 3.3.

    GH-54

## 3.0.6 - 2023-04-14

### Improvements

  * CRuby: Added support for write barrier.

  * JRuby: Added missing arty-checking.

    GH-48

  * JRuby: Added support for `StringIO.new(encoding:)`.

    GH-45

## 3.0.5 - 2023-02-02

### Improvements

### Fixes

  * Fixed a bug that `StringIO#gets("2+ character", chomp: true)` did not
    remove the separator at the end.
    [[Bug #19389](https://bugs.ruby-lang.org/issues/19389)]

## 3.0.4 - 2022-12-09

### Improvements

  * JRuby: Changed to use flag registry.
    [[GitHub#33](https://github.com/ruby/stringio/pull/26)]

## 3.0.3 - 2022-12-08

### Improvements

  * Improved documents.
    [[GitHub#33](https://github.com/ruby/stringio/pull/33)]
    [[GitHub#34](https://github.com/ruby/stringio/pull/34)]
    [[GitHub#35](https://github.com/ruby/stringio/pull/35)]
    [[GitHub#36](https://github.com/ruby/stringio/pull/36)]
    [[GitHub#37](https://github.com/ruby/stringio/pull/37)]
    [Patch by Burdette Lamar]

### Fixes

  * Fixed a bug that large `StringIO#ungetc`/`StringIO#ungetbyte`
    break internal buffer.

  * Fixed a bug that `StringIO#each("2+ character", chomp: true)` cause
    infinite loop.
    [[Bug #18769](https://bugs.ruby-lang.org/issues/18769)]

  * Fixed a bug that `StringIO#each(nil, chomp: true)` chomps.
    [[Bug #18770](https://bugs.ruby-lang.org/issues/18770)]

  * Fixed a bug that `StringIO#each("", chomp: true)` isn't compatible
    with `IO#each("", chomp: true)`.
    [[Bug #18768](https://bugs.ruby-lang.org/issues/18768)]

  * Fixed a bug that `StringIO#set_encoding` doesn't accept external
    and internal encodings pairo.
    [[GitHub#16](https://github.com/ruby/stringio/issues/16)]
    [Reported by Kenta Murata]

  * Fixed a bug that `StringIO#truncate` isn't compatible with
    `File#truncate`.

### Thanks

  * Kenta Murata

  * Burdette Lamar

