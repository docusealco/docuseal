FROM ruby:4.0.1-alpine AS download

WORKDIR /fonts

RUN apk --no-cache add wget && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/fonts/DancingScript-Regular.otf && \
    wget https://raw.githubusercontent.com/impallari/DancingScript/master/OFL.txt && \
    wget https://raw.githubusercontent.com/notofonts/noto-fonts/refs/heads/main/LICENSE && \
    wget https://github.com/google/fonts/raw/main/ofl/greatvibes/GreatVibes-Regular.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/pacifico/Pacifico-Regular.ttf && \
    wget -O Caveat-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf" && \
    wget https://github.com/google/fonts/raw/main/apache/homemadeapple/HomemadeApple-Regular.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/mrssaintdelafield/MrsSaintDelafield-Regular.ttf && \
    wget -O ShadowsIntoLight-Regular.ttf https://github.com/google/fonts/raw/main/ofl/shadowsintolight/ShadowsIntoLight.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/alexbrush/AlexBrush-Regular.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/kalam/Kalam-Regular.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/sacramento/Sacramento-Regular.ttf && \
    wget https://github.com/google/fonts/raw/main/ofl/herrvonmuellerhoff/HerrVonMuellerhoff-Regular.ttf && \
    wget -O /model.onnx "https://github.com/docusealco/fields-detection/releases/download/2.0.0/model_704_int8.onnx" && \
    wget -O pdfium-linux.tgz "https://github.com/bblanchon/pdfium-binaries/releases/latest/download/pdfium-linux-musl-$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/').tgz" && \
    mkdir -p /pdfium-linux && \
    tar -xzf pdfium-linux.tgz -C /pdfium-linux

FROM ruby:4.0.1-alpine AS webpack

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
COPY ./tailwind.dynamic.config.js ./tailwind.dynamic.config.js
COPY ./tailwind.application.config.js ./tailwind.application.config.js
COPY ./app/javascript ./app/javascript
COPY ./app/views ./app/views

RUN echo "gem 'shakapacker'" > Gemfile && ./bin/shakapacker

FROM ruby:4.0.1-alpine AS app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV OPENSSL_CONF=/etc/openssl_legacy.cnf

WORKDIR /app

RUN apk add --no-cache libpq vips redis vips-heif onnxruntime

RUN addgroup -g 2000 docuseal && adduser -u 2000 -G docuseal -s /bin/sh -D -h /home/docuseal docuseal

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
activate = 1' >> /etc/openssl_legacy.cnf

COPY --chown=docuseal:docuseal ./Gemfile ./Gemfile.lock ./

RUN apk add --no-cache build-base git libpq-dev yaml-dev && bundle install && apk del --no-cache build-base git libpq-dev yaml-dev && rm -rf ~/.bundle /usr/local/bundle/cache && ruby -e "puts Dir['/usr/local/bundle/**/{spec,rdoc,resources/shared,resources/collation,resources/locales,resources/unicode_data/properties}'] + Dir['/usr/local/bundle/gems/*/{test,tests,examples,sample,misc,doc,docs}'] + Dir['/usr/local/bundle/gems/*/ext/**/*.{c,h,o,S}']" | xargs rm -rf && ln -sf /usr/lib/libonnxruntime.so.1 $(ruby -e "print Dir[Gem::Specification.find_by_name('onnxruntime').gem_dir + '/vendor/*.so'].first")

COPY --chown=docuseal:docuseal ./bin ./bin
COPY --chown=docuseal:docuseal ./app ./app
COPY --chown=docuseal:docuseal ./config ./config
COPY --chown=docuseal:docuseal ./db/migrate ./db/migrate
COPY --chown=docuseal:docuseal ./log ./log
COPY --chown=docuseal:docuseal ./lib ./lib
COPY --chown=docuseal:docuseal ./public ./public
COPY --chown=docuseal:docuseal ./tmp ./tmp
COPY --chown=docuseal:docuseal LICENSE LICENSE_ADDITIONAL_TERMS README.md Rakefile config.ru .version ./
COPY --chown=docuseal:docuseal .version ./public/version

COPY --chown=docuseal:docuseal --from=download /fonts/ /fonts/
COPY --from=download /pdfium-linux/lib/libpdfium.so /usr/lib/libpdfium.so
COPY --from=download /pdfium-linux/licenses/pdfium.txt /usr/lib/libpdfium-LICENSE.txt
COPY --chown=docuseal:docuseal --from=download /model.onnx /app/tmp/model.onnx
COPY --chown=docuseal:docuseal --from=webpack /app/public/packs ./public/packs

RUN mkdir -p /app/public/fonts && \
    for f in DancingScript-Regular.otf GreatVibes-Regular.ttf Pacifico-Regular.ttf Caveat-Regular.ttf HomemadeApple-Regular.ttf MrsSaintDelafield-Regular.ttf ShadowsIntoLight-Regular.ttf AlexBrush-Regular.ttf Kalam-Regular.ttf Sacramento-Regular.ttf HerrVonMuellerhoff-Regular.ttf; do \
      ln -s /fonts/$f /app/public/fonts/; \
    done && \
    mkdir -p /usr/share/fonts/noto && ln -s /fonts/GoNotoKurrent-Regular.ttf /usr/share/fonts/noto/ && ln -s /fonts/GoNotoKurrent-Bold.ttf /usr/share/fonts/noto/ && fc-cache -f && \
    bundle exec bootsnap precompile -j 1 --gemfile app/ lib/ && \
    chown -R docuseal:docuseal /app/tmp/cache

WORKDIR /data/docuseal
ENV HOME=/home/docuseal
ENV WORKDIR=/data/docuseal
ENV VIPS_MAX_COORD=17000

EXPOSE 3000
CMD ["/app/bin/bundle", "exec", "puma", "-C", "/app/config/puma.rb", "--dir", "/app"]
