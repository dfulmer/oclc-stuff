ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}


ARG UNAME=app
ARG UID=1000
ARG GID=1000


LABEL maintainer="dfulmer@umich.edu"

## Install Vim (optional)
#RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends \
#  vim-tiny

RUN gem install bundler

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install requests oauthlib requests_oauthlib --break-system-packages

RUN groupadd -g ${GID} -o ${UNAME}
RUN useradd -m -d /app -u ${UID} -g ${GID} -o -s /bin/bash ${UNAME}
RUN mkdir -p /gems && chown ${UID}:${GID} /gems

USER $UNAME

ENV BUNDLE_PATH /gems

WORKDIR /app

##For a production build copy the app files and run bundle install
#COPY --chown=${UID}:${GID} . /app
#RUN bundle _${BUNDLER_VERSION}_ install

CMD ["tail", "-f", "/dev/null"]