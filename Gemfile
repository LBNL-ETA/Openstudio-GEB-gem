source 'http://rubygems.org'

gemspec

# Local gems are useful when developing and integrating the various dependencies.
# To favor the use of local gems, set the following environment variable:
#   Mac: export FAVOR_LOCAL_GEMS=1
#   Windows: set FAVOR_LOCAL_GEMS=1
# Note that if allow_local is true, but the gem is not found locally, then it will
# checkout the latest version (develop) from github.
# allow_local = ENV['FAVOR_LOCAL_GEMS']
#
# if allow_local && File.exists?('../OpenStudio-extension-gem')
#   gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
# else
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'faraday'
# end
# Delete this once testing is complete!
gem 'bcl', github: 'NREL/bcl-gem', branch: 'faraday'
