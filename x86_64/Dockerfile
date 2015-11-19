#
# DSC Alarm connect service
#
# http://github.com/tenstartups/dsc-alarm-connect-docker
#

FROM tenstartups/alpine-ruby:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  RUBYLIB=/usr/local/lib

# Install packages.
RUN \
  apk --update add libxml2-dev libxslt-dev ruby-nokogiri zlib-dev && \
  rm -rf /var/cache/apk/*

# Install gems.
RUN \
  gem install --no-ri --no-rdoc activesupport awesome_print colorize pry rest-client sinatra tzinfo-data && \
  gem install nokogiri -- --use-system-libraries

# Add files to the container.
COPY lib /usr/local/lib
COPY entrypoint.rb /docker-entrypoint

# Set the entrypoint script.
ENTRYPOINT ["/docker-entrypoint"]
