FROM debian:10.13

WORKDIR /pg

# Debian 10.13 is EOL now:
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list

RUN apt-get update && apt-get install ruby git wget gcc make libz-dev libffi-dev libreadline-dev libyaml-dev libssl-dev -y

ENV RBENV_ROOT=/usr/local/rbenv

RUN git clone https://github.com/rbenv/rbenv.git      ${RBENV_ROOT} && \
    git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
    $RBENV_ROOT/bin/rbenv init

RUN $RBENV_ROOT/bin/rbenv install 3.3.9 -- --disable-install-doc
RUN /usr/local/rbenv/versions/3.3.9/bin/gem inst rspec

CMD /usr/local/rbenv/versions/3.3.9/bin/gem inst --local pg-*.gem && \
    /usr/local/rbenv/versions/3.3.9/bin/rspec glibc_spec.rb
