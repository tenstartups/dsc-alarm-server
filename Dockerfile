#
# DSC ISY bridge server
#
# http://github.com/tenstartups/dsc-isy-bridge-docker
#

FROM tenstartups/rpi-alpine-ruby:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  RUBYLIB=/usr/local/lib/dsc-isy

# Install packages.
RUN \
  apk --update add libxml2-dev libxslt-dev ruby-nokogiri zlib-dev && \
  rm -rf /var/cache/apk/*

# Install gems.
RUN \
  gem install --no-ri --no-rdoc awesome_print colorize rest-client tzinfo-data && \
  gem install nokogiri -- --use-system-libraries

# Add files to the container.
COPY lib /usr/local/lib/dsc-isy
COPY entrypoint.rb /docker-entrypoint

# Set the entrypoint script.
ENTRYPOINT ["/docker-entrypoint"]
