FROM ruby:2.6.10

RUN apt-get update && apt-get -yq install --no-install-suggests --no-install-recommends \
  build-essential \
  imagemagick \
  libmagic-dev \
  wkhtmltopdf

# Needed to get the latest libreoffice
# Ref: https://wiki.debian.org/LibreOffice#Using_Debian_backports
RUN echo 'deb https://deb.debian.org/debian bullseye-backports main contrib non-free' >> /etc/apt/sources.list

# Needed for Tesseract 5
# Ref: https://notesalexp.org/tesseract-ocr/html/
RUN echo 'deb https://notesalexp.org/tesseract-ocr5/bullseye bullseye main' >> /etc/apt/sources.list
RUN wget -qO /etc/apt/trusted.gpg.d/alexp_key.asc https://notesalexp.org/debian/alexp_key.asc

RUN apt-get update && apt-get -yq -t bullseye-backports install \
  libreoffice \
  tesseract-ocr \
  tesseract-ocr-ara \
  tesseract-ocr-fra \
  tesseract-ocr-spa

ARG TIKA_VERSION=3.2.2

RUN wget --quiet https://dlcdn.apache.org/tika/KEYS -O tika-keys && \
  wget --quiet https://dlcdn.apache.org/tika/${TIKA_VERSION}/tika-app-${TIKA_VERSION}.jar.asc -O tika-app.jar.asc && \
  wget --quiet https://dlcdn.apache.org/tika/${TIKA_VERSION}/tika-app-${TIKA_VERSION}.jar -O tika-app.jar && \
  gpg --import tika-keys && \
  gpg --verify tika-app.jar.asc tika-app.jar && \
  rm -f tika-app.jar.asc tika-keys && \
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

RUN gem install bundler -v 2.4.22

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
