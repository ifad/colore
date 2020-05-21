FROM ruby:2.6.5

RUN apt-get update && apt-get install -y \
  build-essential \
  imagemagick \
  libmagic-dev \
  libreoffice \
  tesseract-ocr

# Please keep using version 0.12.3
# With newer version of 0.12.x, the following issues are more annoying:
# wkhtmltopdf/wkhtmltopdf#1524 wkhtmltopdf/wkhtmltopdf#3241
ARG WKHTMLTOPDF_VERSION=0.12.3
ARG WKHTMLTOPDF_MD5=6e991e1a1f3293ab673afa015703ef86

RUN wget --quiet https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz -O wkhtmltox.tar.xz && \
    echo "${WKHTMLTOPDF_MD5} wkhtmltox.tar.xz" > MD5SUMS && \
    md5sum -c MD5SUMS && \
    tar -xf wkhtmltox.tar.xz && \
    mv wkhtmltox/bin/wkhtmltopdf /usr/local/bin && \
    rm -rf wkhtmltox wkhtmltox.tar.xz MD5SUMS

ARG TIKA_VERSION=1.25

RUN gpg --keyserver hkp://keys.gnupg.net --recv-key 184454FAD8697760F3E00D2E4A51A45B944FFD51 && \
  wget --quiet https://archive.apache.org/dist/tika/tika-app-${TIKA_VERSION}.jar.asc -O tika-app.jar.asc && \
  wget --quiet https://archive.apache.org/dist/tika/tika-app-${TIKA_VERSION}.jar -O tika-app.jar && \
  gpg --verify tika-app.jar.asc tika-app.jar && \
  rm -f tika-app.jar.asc && \
  mv tika-app.jar /usr/share/java/tika-app.jar && \
  echo '#!/bin/sh\n\nARGS="$@"\n\n[ $# -eq 0 ] && ARGS="--help"\n\nexec java -jar /usr/share/java/tika-app.jar $ARGS\n' > /usr/local/bin/tika && \
  chmod +x /usr/local/bin/tika

ENV APP_DIR /colore

EXPOSE 9240

WORKDIR $APP_DIR

# Create application user and add permissions
RUN groupadd --gid 1000 colore && \
    useradd --uid 1000 --gid colore --shell /bin/bash --create-home colore && \
    chown -R colore:colore $APP_DIR && \
    chmod -R 755 $APP_DIR

# Switch to application user
USER colore

RUN mkdir -p log
RUN mkdir -p tmp/pids

ARG RACK_ENV
ENV RACK_ENV=${RACK_ENV:-production}

RUN gem install bundler

# Copy command always runs as root
COPY --chown=colore:colore Gemfile .
COPY --chown=colore:colore Gemfile.lock .

RUN echo $RACK_ENV
RUN \
  if [ "$RACK_ENV" = "development" ] || [ "$RACK_ENV" = "test" ]; then \
    bundle install --retry 10; \
  else \
    bundle config set deployment 'true' && bundle --retry 10; \
  fi

COPY --chown=colore:colore bin ./bin
COPY --chown=colore:colore config ./config
COPY --chown=colore:colore lib ./lib
COPY --chown=colore:colore spec ./spec
COPY --chown=colore:colore config.ru .
COPY --chown=colore:colore Rakefile .
COPY --chown=colore:colore unicorn.rb .

# Create the shared volume so it will be owned by the application user
RUN mkdir -p storage

COPY --chown=colore:colore docker/colore/docker-entrypoint.sh ./bin
RUN chmod +x ./bin/docker-entrypoint.sh

ENTRYPOINT ["/colore/bin/docker-entrypoint.sh"]

CMD ["bundle", "exec", "unicorn"]
