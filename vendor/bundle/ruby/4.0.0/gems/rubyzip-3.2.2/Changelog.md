# 3.2.2 (2025-11-02)

- Fix reading EOCDs when header signatures are in an Entry payload. [#656](https://github.com/rubyzip/rubyzip/issues/656)

Tooling/internal:

- Stop using macos-13 runners in GitHub Actions.
- Update YJIT GitHub Actions runners.

# 3.2.1 (2025-10-24)

- Fix `Entry#gather_fileinfo_from_srcpath` error messages. [#654](https://github.com/rubyzip/rubyzip/issues/654)

Tooling/internal:

- Add some simple benchmarks for reading the cdir.

# 3.2.0 (2025-10-14)

- Add option to suppress extra fields. [#653](https://github.com/rubyzip/rubyzip/pull/653) (fixes [#34](https://github.com/rubyzip/rubyzip/issues/34), [#398](https://github.com/rubyzip/rubyzip/issues/398) and [#648](https://github.com/rubyzip/rubyzip/issues/648))

Tooling/internal:

- Entry: clean up reading and writing the Central Directory headers.
- Improve Zip64 tests for `OutputStream`.
- Extra fields: use symbols as indices as opposed to strings.
- Ensure that `Unknown` extra field has a superclass.

# 3.1.1 (2025-09-26)

- Improve the IO pipeline when decompressing. [#649](https://github.com/rubyzip/rubyzip/pull/649) (which also fixes [#647](https://github.com/rubyzip/rubyzip/issues/647))

Tooling/internal:

- Improve the `DecryptedIo` class with various updates and optimizations.
- Remove the `NullDecrypter` class.
- Properly convert the test suite to use minitest.
- Move all test helper code into separate files.
- Updates to the Actions CI, including new OS versions.
- Update rubocop versions and fix resultant cop failures. [#646](https://github.com/rubyzip/rubyzip/pull/646)

# 3.1.0 (2025-09-06)

- Support AES decryption. [#579](https://github.com/rubyzip/rubyzip/pull/579) and [#645](https://github.com/rubyzip/rubyzip/pull/645)

Tooling/internal:

- Add various useful zip specification documents to the repo for ease of finding them in the future. These are not included in the gem release.

# 3.0.2 (2025-08-21)

- Fix `InputStream#sysread` to handle frozen string literals. [#643](https://github.com/rubyzip/rubyzip/pull/643)
- Ensure that we don't flush too often when deflating. [#322](https://github.com/rubyzip/rubyzip/issues/322)
- Stop `print` causing Zlib errors. [#642](https://github.com/rubyzip/rubyzip/issues/642)
- Ensure that `print` and `printf` return `nil`.

# 3.0.1 (2025-08-08)

- Restore `Zip::File`'s `Enumerable` status. [#641](https://github.com/rubyzip/rubyzip/issues/641)
- Escape filename pattern when matching in `Entry#name_safe?`. [#639](https://github.com/rubyzip/rubyzip/pull/639)
- Eagerly require gem version. [#637](https://github.com/rubyzip/rubyzip/pull/637)
- Fix direct `require` of `Entry` by requiring `constants`. [#636](https://github.com/rubyzip/rubyzip/pull/636)

# 3.0.0 (2025-07-28)

- Fix de facto regression for input streams.
- Fix `File#write_buffer` to always return the given `io`.
- Add `Entry#absolute_time?` and `DOSTime#absolute_time?` methods.
- Use explicit named parameters for `File` methods.
- Ensure that entries can be extracted safely without path traversal. [#540](https://github.com/rubyzip/rubyzip/issues/540)
- Enable Zip64 by default.
- Rename `GPFBit3Error` to `StreamingError`.
- Ensure that `Entry.ftype` is correct via `InputStream`. [#533](https://github.com/rubyzip/rubyzip/issues/533)
- Add `Entry#zip64?` as a better way detect Zip64 entries.
- Implement `Zip::FileSystem::ZipFsFile#symlink?`.
- Remove `File::add_buffer` from the API.
- Fix `OutputStream#put_next_entry` to preserve `StreamableStream`s. [#503](https://github.com/rubyzip/rubyzip/issues/503)
- Ensure `File.open_buffer` doesn't rewrite unchanged data.
- Add `CentralDirectory#count_entries` and `File::count_entries`.
- Fix reading unknown extra fields. [#505](https://github.com/rubyzip/rubyzip/issues/505)
- Fix reading zip files with max length file comment. [#508](https://github.com/rubyzip/rubyzip/issues/508)
- Fix reading zip64 files with max length file comment. [#509](https://github.com/rubyzip/rubyzip/issues/509)
- Don't silently alter zip files opened with `Zip::sort_entries`. [#329](https://github.com/rubyzip/rubyzip/issues/329)
- Use named parameters for optional arguments in the public API.
- Raise an error if entry names exceed 65,535 characters. [#247](https://github.com/rubyzip/rubyzip/issues/247)
- Remove the `ZipXError` v1 legacy classes.
- Raise an error on reading a split archive with `InputStream`. [#349](https://github.com/rubyzip/rubyzip/issues/349)
- Ensure `InputStream` raises `GPFBit3Error` for OSX Archive files. [#493](https://github.com/rubyzip/rubyzip/issues/493)
- Improve documentation and error messages for `InputStream`. [#196](https://github.com/rubyzip/rubyzip/issues/196)
- Fix zip file-level comment is not read from zip64 files. [#492](https://github.com/rubyzip/rubyzip/issues/492)
- Fix `Zip::OutputStream.write_buffer` doesn't work with Tempfiles. [#265](https://github.com/rubyzip/rubyzip/issues/265)
- Reinstate normalising pathname separators to /. [#487](https://github.com/rubyzip/rubyzip/pull/487)
- Fix restore options consistency. [#486](https://github.com/rubyzip/rubyzip/pull/486)
- View and/or preserve original date created, date modified? (Windows). [#336](https://github.com/rubyzip/rubyzip/issues/336)
- Fix frozen string literal error. [#475](https://github.com/rubyzip/rubyzip/pull/475)
- Set the default `Entry` time to the file's mtime on Windows. [#465](https://github.com/rubyzip/rubyzip/issues/465)
- Ensure that `Entry#time=` sets times as `DOSTime` objects. [#481](https://github.com/rubyzip/rubyzip/issues/481)
- Replace and deprecate `Zip::DOSTime#dos_equals`. [#464](https://github.com/rubyzip/rubyzip/pull/464)
- Fix loading extra fields. [#459](https://github.com/rubyzip/rubyzip/pull/459)
- Set compression level on a per-zipfile basis. [#448](https://github.com/rubyzip/rubyzip/pull/448)
- Fix input stream partial read error. [#462](https://github.com/rubyzip/rubyzip/pull/462)
- Fix zlib deflate buffer growth. [#447](https://github.com/rubyzip/rubyzip/pull/447)

Tooling/internal:

- No longer test setting `$\` in tests.
- Add a test to ensure correct version number format.
- Update the README with new Ruby version compatability information.
- Fix various issues with JRuby tests.
- Update gem dependency versions.
- Add Ruby 3.4 to the CI.
- Fix mispelled variable names in the crypto classes.
- Only use the Zip64 CDIR end locator if needed.
- Prevent unnecessary Zip64 data being stored.
- Abstract marking various things as 'dirty' into `Dirtyable` for reuse.
- Properly test `File#mkdir`.
- Remove unused private method `File#directory?`.
- Expose the `EntrySet` more cleanly through `CentralDirectory`.
- `Zip::File` no longer subclasses `Zip::CentralDirectory`.
- Configure Coveralls to not report a failure on minor decreases of test coverage. [#491](https://github.com/rubyzip/rubyzip/issues/491)
- Extract the file splitting code out into its own module.
- Refactor, and tidy up, the `Zip::Filesystem` classes for improved maintainability.
- Fix Windows tests. [#489](https://github.com/rubyzip/rubyzip/pull/489)
- Refactor `assert_forwarded` so it does not need `ObjectSpace._id2ref` or `eval`. [#483](https://github.com/rubyzip/rubyzip/pull/483)
- Add GitHub Actions CI infrastructure. [#469](https://github.com/rubyzip/rubyzip/issues/469)
- Add Ruby 3.0 to CI. [#474](https://github.com/rubyzip/rubyzip/pull/474)
- Fix the compression level tests to compare relative sizes. [#473](https://github.com/rubyzip/rubyzip/pull/473)
- Simplify assertions in basic_zip_file_test. [#470](https://github.com/rubyzip/rubyzip/pull/470)
- Remove compare_enumerables from test_helper.rb. [#468](https://github.com/rubyzip/rubyzip/pull/468)
- Use correct SPDX license identifier. [#458](https://github.com/rubyzip/rubyzip/pull/458)
- Enable truffle ruby in Travis CI. [#450](https://github.com/rubyzip/rubyzip/pull/450)
- Update rubocop again and run it in CI. [#444](https://github.com/rubyzip/rubyzip/pull/444)
- Fix a test that was incorrect on big-endian architectures. [#445](https://github.com/rubyzip/rubyzip/pull/445)

# 2.4.1 (2025-01-05)

*This is a re-release of version 2.4 with a full version number string. We need to move to version 2.4.1 due to the canonical version number 2.4 now being taken in Rubygems.*

Tooling:

- Opt-in for MFA requirement explicitly on 2.4 branch.

# 2.4 (2025-01-04) - Yanked

*Yanked due to incorrect version number format (2.4 vs 2.4.0).*

- Ensure compatibility with `--enable-frozen-string-literal`.
- Ensure `File.open_buffer` doesn't rewrite unchanged data. This is a backport of the fix on the 3.x branch.
- Enable use of the version 3 calling style (mainly named parameters) wherever possible, while retaining version 2.x compatibility.
- Add (switchable) warning messages to methods that are changed or removed in version 3.x.

Tooling:

- Switch to using GitHub Actions (from Travis).
- Update Rubocop versions and configuration.
- Update actions with latest rubies.

# 2.3.2 (2021-07-05)

- A "dummy" release to warn about breaking changes coming in version 3.0. This updated version uses the Gem `post_install_message` instead of printing to `STDERR`.

# 2.3.1 (2021-07-03)

- A "dummy" release to warn about breaking changes coming in version 3.0.

# 2.3.0 (2020-03-14)

- Fix frozen string literal error [#431](https://github.com/rubyzip/rubyzip/pull/431)
- Set `OutputStream.write_buffer`'s buffer to binmode [#439](https://github.com/rubyzip/rubyzip/pull/439)
- Upgrade rubocop and fix various linting complaints [#437](https://github.com/rubyzip/rubyzip/pull/437) [#440](https://github.com/rubyzip/rubyzip/pull/440)

Tooling:

- Add a `bin/console` script for development [#420](https://github.com/rubyzip/rubyzip/pull/420)
- Update rake requirement (development dependency only) to fix a security alert.

# 2.2.0 (2020-02-01)

- Add support for decompression plugin gems [#427](https://github.com/rubyzip/rubyzip/pull/427)

# 2.1.0 (2020-01-25)

- Fix (at least partially) the `restore_times` and `restore_permissions` options to `Zip::File.new` [#413](https://github.com/rubyzip/rubyzip/pull/413)
  - Previously, neither option did anything, regardless of what it was set to. We have therefore defaulted them to `false` to preserve the current behavior, for the time being. If you have explicitly set either to `true`, it will now have an effect.
  - Fix handling of UniversalTime (`mtime`, `atime`, `ctime`) fields. [#421](https://github.com/rubyzip/rubyzip/pull/421)
  - Previously, `Zip::File` did not pass the options to `Zip::Entry` in some cases. [#423](https://github.com/rubyzip/rubyzip/pull/423)
  - Note that `restore_times` in this release does nothing on Windows and only restores `mtime`, not `atime` or `ctime`.
- Allow `Zip::File.open` to take an options hash like `Zip::File.new` [#418](https://github.com/rubyzip/rubyzip/pull/418)
- Always print warnings with `warn`, instead of a mix of `puts` and `warn` [#416](https://github.com/rubyzip/rubyzip/pull/416)
- Create temporary files in the system temporary directory instead of the directory of the zip file [#411](https://github.com/rubyzip/rubyzip/pull/411)
- Drop unused `tmpdir` requirement [#411](https://github.com/rubyzip/rubyzip/pull/411)

Tooling

- Move CI to xenial and include jruby on JDK11 [#419](https://github.com/rubyzip/rubyzip/pull/419/files)

# 2.0.0 (2019-09-25)

Security

- Default the `validate_entry_sizes` option to `true`, so that callers can trust an entry's reported size when using `extract` [#403](https://github.com/rubyzip/rubyzip/pull/403)
  - This option defaulted to `false` in 1.3.0 for backward compatibility, but it now defaults to `true`. If you are using an older version of ruby and can't yet upgrade to 2.x, you can still use 1.3.0 and set the option to `true`.

Tooling / Documentation

- Remove test files from the gem to avoid problems with antivirus detections on the test files [#405](https://github.com/rubyzip/rubyzip/pull/405) / [#384](https://github.com/rubyzip/rubyzip/issues/384)
- Drop support for unsupported ruby versions [#406](https://github.com/rubyzip/rubyzip/pull/406)

# 1.3.0 (2019-09-25)

Security

- Add `validate_entry_sizes` option so that callers can trust an entry's reported size when using `extract` [#403](https://github.com/rubyzip/rubyzip/pull/403)
  - This option defaults to `false` for backward compatibility in this release, but you are strongly encouraged to set it to `true`. It will default to `true` in rubyzip 2.0.

New Feature

- Add `add_stored` method to simplify adding entries without compression [#366](https://github.com/rubyzip/rubyzip/pull/366)

Tooling / Documentation

- Add more gem metadata links [#402](https://github.com/rubyzip/rubyzip/pull/402)

# 1.2.4 (2019-09-06)

- Do not rewrite zip files opened with `open_buffer` that have not changed [#360](https://github.com/rubyzip/rubyzip/pull/360)

Tooling / Documentation

- Update `example_recursive.rb` in README [#397](https://github.com/rubyzip/rubyzip/pull/397)
- Hold CI at `trusty` for now, automatically pick the latest ruby patch version, use rbx-4 and hold jruby at 9.1 [#399](https://github.com/rubyzip/rubyzip/pull/399)

# 1.2.3

- Allow tilde in zip entry names [#391](https://github.com/rubyzip/rubyzip/pull/391) (fixes regression in 1.2.2 from [#376](https://github.com/rubyzip/rubyzip/pull/376))
- Support frozen string literals in more files [#390](https://github.com/rubyzip/rubyzip/pull/390)
- Require `pathname` explicitly [#388](https://github.com/rubyzip/rubyzip/pull/388) (fixes regression in 1.2.2 from [#376](https://github.com/rubyzip/rubyzip/pull/376))

Tooling / Documentation:

- CI updates [#392](https://github.com/rubyzip/rubyzip/pull/392), [#394](https://github.com/rubyzip/rubyzip/pull/394)
  - Bump supported ruby versions and add 2.6
  - JRuby failures are no longer ignored (reverts [#375](https://github.com/rubyzip/rubyzip/pull/375) / part of [#371](https://github.com/rubyzip/rubyzip/pull/371))
- Add changelog entry that was missing for last release [#387](https://github.com/rubyzip/rubyzip/pull/387)
- Comment cleanup [#385](https://github.com/rubyzip/rubyzip/pull/385)

# 1.2.2

NB: This release drops support for extracting symlinks, because there was no clear way to support this securely. See https://github.com/rubyzip/rubyzip/pull/376#issue-210954555 for details.

- Fix CVE-2018-1000544 [#376](https://github.com/rubyzip/rubyzip/pull/376) / [#371](https://github.com/rubyzip/rubyzip/pull/371)
- Fix NoMethodError: undefined method `glob' [#363](https://github.com/rubyzip/rubyzip/pull/363)
- Fix handling of stored files (i.e. files not using compression) with general purpose bit 3 set [#358](https://github.com/rubyzip/rubyzip/pull/358)
- Fix `close` on StringIO-backed zip file [#353](https://github.com/rubyzip/rubyzip/pull/353)
- Add `Zip.force_entry_names_encoding` option [#340](https://github.com/rubyzip/rubyzip/pull/340)
- Update rubocop, apply auto-fixes, and fix regressions caused by said auto-fixes [#332](https://github.com/rubyzip/rubyzip/pull/332), [#355](https://github.com/rubyzip/rubyzip/pull/355)
- Save temporary files to temporary directory (rather than current directory) [#325](https://github.com/rubyzip/rubyzip/pull/325)

Tooling / Documentation:

- Turn off all terminal output in all tests [#361](https://github.com/rubyzip/rubyzip/pull/361)
- Several CI updates [#346](https://github.com/rubyzip/rubyzip/pull/346), [#347](https://github.com/rubyzip/rubyzip/pull/347), [#350](https://github.com/rubyzip/rubyzip/pull/350), [#352](https://github.com/rubyzip/rubyzip/pull/352)
- Several README improvements [#345](https://github.com/rubyzip/rubyzip/pull/345), [#326](https://github.com/rubyzip/rubyzip/pull/326), [#321](https://github.com/rubyzip/rubyzip/pull/321)

# 1.2.1

- Add accessor to @internal_file_attributes #304
- Extended globbing #303
- README updates #283, #289
- Cleanup after tests #298, #306
- Fix permissions on new zip files #294, #300
- Fix examples #297
- Support cp932 encoding #308
- Fix Directory traversal vulnerability #315
- Allow open_buffer to work without a given block #314

# 1.2.0

- Don't enable JRuby objectspace #252
- Fixes an exception thrown when decoding some weird .zip files #248
- Use duck typing with IO methods #244
- Added error for empty (zero bit) zip file #242
- Accept StringIO in Zip.open_buffer #238
- Do something more expected with new file permissions #237
- Case insensitivity option for #find_entry #222
- Fixes in documentation and examples

# 1.1.7

- Fix UTF-8 support for comments
- `Zip.sort_entries` working for zip output
- Prevent tempfile path from being unlinked by garbage collection
- NTFS Extra Field (0x000a) support
- Use String#tr instead of String#gsub
- Ability to not show warning about incorrect date
- Be smarter about handling buffer file modes.
- Support for Traditional Encryption (ZipCrypto)

# 1.1.6

- Revert "Return created zip file from Zip::File.open when supplied a block"

# 1.1.5

- Treat empty file as non-exists (@layerssss)
- Revert regression commit
- Return created zip file from Zip::File.open when supplied a block (@tpickett66)
- Zip::Entry::DEFLATED is forced on every file (@mehmetc)
- Add InputStream#ungetc (@zacstewart)
- Alias for legacy error names (@orien)

# 1.1.4

- Don't send empty string to stream (@mrloop)
- Zip::Entry::DEFLATED was forced on every file (@mehmetc)
- Alias for legacy error names (@orien)

# 1.1.3

- Fix compatibility of ::OutputStream::write_buffer (@orien)
- Clean up tempfiles from output stream (@iangreenleaf)

# 1.1.2

- Fix compatibility of ::Zip::File.write_buffer

# 1.1.1

- Speedup deflater (@loadhigh)
- Less Arrays and Strings allocations (@srawlins)
- Fix Zip64 writing support (@mrjamesriley)
- Fix StringIO support (@simonoff)
- Possibility to change default compression level
- Make Zip64 write support optional via configuration

# 1.1.0

- StringIO Support
- Zip64 Support
- Better jRuby Support
- Order of files in the archive can be sorted
- Other small fixes

# 1.0.0

- Removed support for Ruby 1.8
- Changed the API for gem. Now it can be used without require param in Gemfile.
- Added read-only support for Zip64 files.
- Added support for setting Unicode file names.

# 0.9.9

- Added support for backslashes in zip files (generated by the default Windows zip packer for example) and comment sections with the comment length set to zero even though there is actually a comment.

# 0.9.8

- Fixed: "Unitialized constant NullInputStream" error

# 0.9.5

- Removed support for loading ruby in zip files (ziprequire.rb).

# 0.9.4

- Changed ZipOutputStream.put_next_entry signature (API CHANGE!). Now allows comment, extra field and compression method to be specified.

# 0.9.3

- Fixed: Added ZipEntry::name_encoding which retrieves the character encoding of the name and comment of the entry.
- Added convenience methods ZipEntry::name_in(enc) and ZipEntry::comment_in(enc) for getting zip entry names and comments in a specified character encoding.

# 0.9.2

- Fixed: Renaming an entry failed if the entry's new name was a different length than its old name. (Diego Barros)

# 0.9.1

- Added symlink support and support for unix file permissions. Reduced memory usage during decompression.
- New methods ZipFile::[follow_symlinks, restore_times, restore_permissions, restore_ownership].
- New methods ZipEntry::unix_perms, ZipInputStream::eof?.
- Added documentation and test for new ZipFile::extract.
- Added some of the API suggestions from sf.net #1281314.
- Applied patch for sf.net bug #1446926.
- Applied patch for sf.net bug #1459902.
- Rework ZipEntry and delegate classes.

# 0.5.12

- Fixed problem with writing binary content to a ZipFile in MS Windows.

# 0.5.11

- Fixed name clash file method copy_stream from fileutils.rb. Fixed problem with references to constant CHUNK_SIZE.
- ZipInputStream/AbstractInputStream read is now buffered like ruby IO's read method, which means that read and gets etc can be mixed. The unbuffered read method has been renamed to sysread.

# 0.5.10

- Fixed method name resolution problem with FileUtils::copy_stream and IOExtras::copy_stream.

# 0.5.9

- Fixed serious memory consumption issue

# 0.5.8

- Fixed install script.

# 0.5.7

- install.rb no longer assumes it is being run from the toplevel source dir. Directory structure changed to reflect common ruby library project structure. Migrated from RubyUnit to Test::Unit format. Now uses Rake to build source packages and gems and run unit tests.

# 0.5.6

- Fix for FreeBSD 4.9 which returns Errno::EFBIG instead of Errno::EINVAL for some invalid seeks. Fixed 'version needed to extract'-field incorrect in local headers.

# 0.5.5

- Fix for a problem with writing zip files that concerns only ruby 1.8.1.

# 0.5.4

- Significantly reduced memory footprint when modifying zip files.

# 0.5.3

- Added optimization to avoid decompressing and recompressing individual entries when modifying a zip archive.

# 0.5.2

- Fixed ZipFile corruption bug in ZipFile class. Added basic unix extra-field support.

# 0.5.1

- Fixed ZipFile.get_output_stream bug.

# 0.5.0

- Ruby 1.8.0 and ruby-zlib 0.6.0 compatibility
- Changed method names from camelCase to rubys underscore style.
- Installs to zip/ subdir instead of directly to site_ruby
- Added ZipFile.directory and ZipFile.file - each method return an
  object that can be used like Dir and File only for the contents of the
  zip file.
- Added sample application zipfind which works like Find.find, only
  Zip::ZipFind.find traverses into zip archives too.
- FIX: AbstractInputStream.each_line with non-default separator

# 0.5.0a

Source reorganized. Added ziprequire, which can be used to load ruby modules from a zip file, in a fashion similar to jar files in Java. Added gtk_ruby_zip, another sample application. Implemented ZipInputStream.lineno and ZipInputStream.rewind

Bug fixes:

- Read and write date and time information correctly for zip entries.
- Fixed read() using separate buffer, causing mix of gets/readline/read to cause problems.

# 0.4.2

- Performance optimizations. Test suite runs in half the time.

# 0.4.1

- Windows compatibility fixes.

# 0.4.0

- Zip::ZipFile is now mutable and provides a more convenient way of modifying zip archives than Zip::ZipOutputStream. Operations for adding, extracting, renaming, replacing and removing entries to zip archives are now available.
- Runs without warnings with -w switch.
- Install script install.rb added.

# 0.3.1

- Rudimentary support for writing zip archives.

# 0.2.2

- Fixed and extended unit test suite. Updated to work with ruby/zlib 0.5. It doesn't work with earlier versions of ruby/zlib.

# 0.2.0

- Class ZipFile added. Where ZipInputStream is used to read the individual entries in a zip file, ZipFile reads the central directory in the zip archive, so you can get to any entry in the zip archive without having to skipping through all the preceeding entries.

# 0.1.0

- First working version of ZipInputStream.
