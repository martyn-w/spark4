FROM ruby:2.7.2-alpine
MAINTAINER Martyn Whitwell <martyn.whitwell@gmail.com>

ARG RAILS_ENV=production
ENV RAILS_ENV="$RAILS_ENV"

RUN apk --update add --virtual build-dependencies build-base ruby-dev libressl-dev libxml2-dev libxslt-dev \
    libc-dev linux-headers tzdata git file \
    && gem install bundler

# Set local timezone
RUN cp /usr/share/zoneinfo/Europe/London /etc/localtime && \
    echo "Europe/London" > /etc/timezone

COPY Gemfile Gemfile.lock /spark/

RUN cd /spark && \
    gem install bundler && \
    bundle config build.nokogiri --use-system-libraries \
    && if [ "$RAILS_ENV" = "production" ]; then \
            bundle config set without 'development test'; \
            bundle install; \
        else \
            bundle config set without 'production'; \
            bundle install; \
        fi

COPY . /spark/

WORKDIR "/spark"

CMD ["bin/start-web.sh"]
