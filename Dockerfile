FROM ruby:3.3

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      postgresql-client \
      nodejs \
      npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile ./
RUN bundle install --binstubs
# Generate Gemfile.lock for reference (will be recreated by bundle if needed)
RUN bundle lock

COPY package.json ./
RUN npm install

COPY . .
# Re-run bundle install in case Gemfile changed
RUN bundle install --binstubs

EXPOSE 2300
ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
