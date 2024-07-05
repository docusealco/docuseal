FROM ruby:3.3.3-alpine as fonts

WORKDIR /fonts

RUN apk --no-cache add fontforge wget && wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf && wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf && wget https://github.com/impallari/DancingScript/raw/master/fonts/v2031/DancingScript-Regular.otf && wget https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf && wget https://github.com/Maxattax97/gnu-freefont/raw/master/ttf/FreeSans.ttf && wget https://github.com/impallari/DancingScript/raw/master/OFL.txt

RUN fontforge -lang=py -c 'font1 = fontforge.open("FreeSans.ttf"); font2 = fontforge.open("NotoSansSymbols2-Regular.ttf"); font1.mergeFonts(font2); font1.generate("FreeSans.ttf")'

FROM ruby:3.3.3-alpine as webpack

ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /app

RUN apk add --no-cache nodejs yarn git build-base && \
    gem install shakapacker

COPY ./package.json ./yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY ./bin/shakapacker ./bin/shakapacker
COPY ./config/webpack ./config/webpack
COPY ./config/shakapacker.yml ./config/shakapacker.yml
COPY ./postcss.config.js ./postcss.config.js
COPY ./tailwind.config.js ./tailwind.config.js
COPY ./tailwind.form.config.js ./tailwind.form.config.js
COPY ./tailwind.application.config.js ./tailwind.application.config.js
COPY ./app/javascript ./app/javascript
COPY ./app/views ./app/views

RUN echo "gem 'shakapacker'" > Gemfile && ./bin/shakapacker

FROM ruby:3.3.3-alpine as app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV LD_PRELOAD=/lib/libgcompat.so.0
ENV OPENSSL_CONF=/app/openssl_legacy.cnf

WORKDIR /app

RUN apk add --no-cache sqlite-dev libpq-dev mariadb-dev vips-dev vips-poppler poppler-utils redis vips-heif gcompat ttf-freefont && mkdir /fonts && rm /usr/share/fonts/freefont/FreeSans.otf

RUN echo $'.include = /etc/ssl/openssl.cnf\n\
\n\
[provider_sect]\n\
default = default_sect\n\
legacy = legacy_sect\n\
\n\
[default_sect]\n\
activate = 1\n\
\n\
[legacy_sect]\n\
activate = 1' >> /app/openssl_legacy.cnf

COPY ./Gemfile ./Gemfile.lock ./

RUN apk add --no-cache build-base && bundle install && apk del build-base && rm -rf ~/.bundle /usr/local/bundle/cache && ruby -e "puts Dir['/usr/local/bundle/**/{spec,rdoc,resources/shared,resources/collation,resources/locales}']" | xargs rm -rf

COPY ./bin ./bin
COPY ./app ./app
COPY ./config ./config
COPY ./db ./db
COPY ./log ./log
COPY ./lib ./lib
COPY ./public ./public
COPY ./tmp ./tmp
COPY LICENSE README.md Rakefile config.ru .version ./

COPY --from=fonts /fonts/GoNotoKurrent-Regular.ttf /fonts/GoNotoKurrent-Bold.ttf /fonts/DancingScript-Regular.otf /fonts/OFL.txt /fonts
COPY --from=fonts /fonts/FreeSans.ttf /usr/share/fonts/freefont
COPY --from=webpack /app/public/packs ./public/packs

RUN ln -s /fonts /app/public/fonts
RUN bundle exec bootsnap precompile --gemfile app/ lib/

WORKDIR /data/docuseal
ENV WORKDIR=/data/docuseal

EXPOSE 3000
CMD ["/app/bin/bundle", "exec", "puma", "-C", "/app/config/puma.rb", "--dir", "/app"]
