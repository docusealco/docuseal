# Running the Gauntlet

## Maintaining a Gem Mirror

I use rubygems-mirror to keep an archive of all the latest rubygems on
an external disk. Here is the config:

```
---
- from: https://rubygems.org
  to: /Volumes/StuffA/gauntlet/mirror
  parallelism: 10
  retries: 3
  delete: true
  skiperror: true
  hashdir: true
```

And I update using rake:

```
% cd GIT/rubygems/rubygems-mirror
% git down
% rake mirror:latest
% /Volumes/StuffA/gauntlet/bin/cleanup.rb -y -v
```

This rather quickly updates my mirror to the latest versions of
everything and then deletes all old versions. I then run a cleanup
script that fixes the file dates to their publication date and deletes
any gems that have invalid specs. This can argue with the mirror a
bit, but it is pretty minimal (currently ~20 bad gems).

## Curating an Archive of Ruby Files

Next, I process the gem mirror into a much more digestable structure
using `unpack_gems.rb`.

```
% cd RP/gauntlet
% time caffeinate ./bin/unpack_gems.rb -v [-a] ; say done
... waaaait ...
% DIR=gauntlet.$(today).(all|new).noindex
% mv hashed.noindex $DIR
% tar vc -T <(fd -tf . $DIR | sort) | zstdmt -12 --long > archives/$DIR.tar.zst ; say done
% ./bin/sync.sh
```

This script filters all the newer (< 1 year old) gems (unless `-a` is
used), unpacks them, finds all the files that look like they're valid
ruby, ensures they're valid ruby (using the current version of ruby to
compile them), and then moves them into a SHA dir structure that looks
something like this:

```
hashed.noindex/a/b/c/<full_file_sha>.rb
```

This removes all duplicates and puts everything in a fairly even,
wide, flat directory layout.

This process takes a very long time, even with a lot of
parallelization. There are currently about 160k gems in the mirror.
Unpacking, validating, SHA'ing everything is disk and CPU intensive.
The `.noindex` extension stops spotlight from indexing the continous
churn of files being unpacked and moved and saves time.

Finally, I rename and archive it all up (currently using zstd to
compress).

### Stats

```
9696 % fd -tf . gauntlet.$(today).noindex | wc -l
  561270
3.5G gauntlet.2021-08-06.noindex
239M gauntlet.2021-08-06.noindex.tar.zst
```

So I wind up with a little over half a million unique ruby files to
parse. It's about 3.5g but compresses very nicely down to 240m

## Running the Gauntlet

Assuming you're starting from scratch, unpack the archive once:

```
% tar xf gauntlet.$(today).noindex.tar.zst
```

(BSD tar (and apparently newer gnu tars) can detect and uncompress
most compression formats)

Then, either run a single process (easier to read):

```
% ./gauntlet/bin/gauntlet.rb gauntlet/*.noindex/?
```

Or max out your machine using xargs (note the `-P 16` and choose accordingly):

```
% ls -d gauntlet/*.noindex/?/? | time xargs -n 1 -P 16 ./gauntlet/bin/gauntlet.rb
```

In another terminal I usually monitor the progress like so:

```
% while true ; do clear; fd . -td -te gauntlet/*.noindex -X rmdir -p 2> /dev/null ; for D in gauntlet/*.noindex/? ; do echo -n "$D: "; fd .rb $D | wc -l ; done ; echo ; sleep 30 ; done
```

After this is run and done, there will be files left over that
couldn't be parsed. There will also be a directory with a name like
`gauntlet.slow.1` of files that timed out. What I generally do is wait
for the first run to end and then start increasing the timeout and run
again on the timeout dir:

```
$ ls -d gauntlet.slow.1/*.noindex/?/? | RP_TIMEOUT=30 time xargs -n 1 -P 16 ./gauntlet/bin/gauntlet.rb
# or:
$ RP_TIMEOUT=30 time ./gauntlet/bin/gauntlet.rb gauntlet.slow.*
$ RP_TIMEOUT=60 time ./gauntlet/bin/gauntlet.rb gauntlet.slow.*
$ fd -tf . gauntlet.slow.60/
gauntlet.slow.60/gauntlet.2025-10-22.new.noindex/2/f/f/2ff00bbd2ee63b2145d247570c130823dce2b9fe.rb
gauntlet.slow.60/gauntlet.2025-10-22.new.noindex/a/a/4/aa44d5a214217036425bf8fce5a7ab5b0e04fd92.rb
```

for the most part, you wind up with absurdly large generated ruby files:

```
10022 $ wc -l gauntlet.slow.60/*/?/?/?/*.rb
  412444 gauntlet.slow.60/gauntlet.2025-10-22.new.noindex/2/f/f/2ff00bbd2ee63b2145d247570c130823dce2b9fe.rb
  295249 gauntlet.slow.60/gauntlet.2025-10-22.new.noindex/a/a/4/aa44d5a214217036425bf8fce5a7ab5b0e04fd92.rb
  707693 total
```

and I don't care so much about these.
