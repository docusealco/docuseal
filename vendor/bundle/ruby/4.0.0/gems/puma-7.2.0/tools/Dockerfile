# Use this Dockerfile to create minimal reproductions of issues
# Build (MRI): docker build -f tools/Dockerfile .
# Build (JRuby): docker build -f tools/Dockerfile --build-arg RUBY_IMAGE=jruby:9.4 .

ARG RUBY_IMAGE=ruby:latest
FROM ${RUBY_IMAGE}

# Set BUNDLE_FROZEN=false if you need to update Gemfile.lock during a build.
ARG BUNDLE_FROZEN=true

RUN apt-get update \
  && apt-get install -y --no-install-recommends ragel procps git \
  && rm -rf /var/lib/apt/lists/*

# Only freeze Bundler and compile native extensions when using MRI.
RUN if [ "$(ruby -e 'print RUBY_ENGINE')" = "ruby" ] && [ "${BUNDLE_FROZEN}" = "true" ]; then bundle config --global frozen 1; fi

WORKDIR /usr/src/app

COPY . .

RUN bundle install
RUN if [ "$(ruby -e 'print RUBY_ENGINE')" = "ruby" ]; then bundle exec rake compile; fi

EXPOSE 9292
CMD ["bundle", "exec", "bin/puma", "test/rackup/hello.ru"]
