# Contributing to sqlite3-ruby

**This document is a work-in-progress.**

This doc is a short introduction on how to modify and maintain the sqlite3-ruby gem.


## Architecture notes

### Decision record

As of 2024-09, we're starting to keep some architecture decisions in the subdirectory `/adr`, so
please look there for additional information.

### Garbage collection

All statements keep pointers back to their respective database connections.
The `@connection` instance variable on the `Statement` handle keeps the database
connection alive.

We use `sqlite3_close_v2` in `Database#close` since v2.1.0 which defers _actually_ closing the
connection and freeing the underlying memory until all open statements are closed; though the
`Database` object will immediately behave as though it's been fully closed. If a Database is not
explicitly closed, it will be closed when it is GCed.

`Statement#close` finalizes the underlying statement. If a Statement is not explicitly closed, it
will be closed/finalized when it is GCed.


## Building gems

As a prerequisite please make sure you have `docker` correctly installed, so that you're able to cross-compile the native gems.

Run `bin/build-gems` which will package gems for all supported platforms, and run some basic sanity tests on those packages using `bin/test-gem-set` and `bin/test-gem-file-contents`.


## Updating the version of libsqlite3

Update `/dependencies.yml` to reflect:

- the version of libsqlite3
- the URL from which to download
- the checksum of the file, which will need to be verified manually (see comments in that file)


## Making a release

A quick checklist to cutting a release of the sqlite3 gem:

Prep
- [ ] Make sure CI is green!
- [ ] Update `CHANGELOG.md` and `lib/sqlite3/version.rb`
- [ ] Create a git tag using a format that matches the pattern `v\d+\.\d+\.\d+`, e.g. `v1.3.13`
- [ ] `git push && git push --tags`

Automated build and release
- [ ] Run workflow https://github.com/sparklemotion/sqlite3-ruby/actions/workflows/release.yml
- [ ] Copy checksums from the push job

Manual build and release
- [ ] Run `bin/build-gems` and make sure it completes and all the tests pass
- [ ] `for g in gems/*.gem ; do gem push $g ; done`

Post-release
- [ ] Create a release at https://github.com/sparklemotion/sqlite3-ruby/releases and include sha2 checksums
