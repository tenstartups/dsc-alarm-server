#
# DSC ISY bridge server
#
# http://github.com/tenstartups/dsc-isy-bridge-docker
#

FROM tenstartups/rpi-alpine-ruby:latest

MAINTAINER Marc Lennox <marc.lennox@gmail.com>

# Set environment
ENV \
  HOME=/home/isy \
  RUBYLIB=/home/isy/lib

# Install packages.
RUN \
  apk add --update libxml2-dev libxslt-dev ruby-nokogiri zlib-dev && \
  rm -rf /var/cache/apk/*

# Install gems.
RUN \
  gem install --no-ri --no-rdoc activesupport awesome_print colorize rest-client tzinfo-data && \
  gem install nokogiri -- --use-system-libraries

# Set the working directory.
WORKDIR "/home/isy"

# Add files to the container.
COPY lib lib
COPY entrypoint.rb /docker-entrypoint

# Set the entrypoint script.
ENTRYPOINT ["/docker-entrypoint"]

# Set the default command
CMD ["/bin/bash"]
