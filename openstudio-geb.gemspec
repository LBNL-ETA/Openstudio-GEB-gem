
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/geb/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-geb'
  spec.version       = OpenStudio::Geb::VERSION
  spec.authors       = ['Kaiyu Sun', 'Wanni Zhang']
  spec.email         = ['ksun@lbl.gov', 'wannizhang@lbl.gov']

  spec.summary       = 'OpenStudio measures for grid-interactive efficient buildings'
  spec.description   = 'This is a Ruby gem that implemented a series of OpenStudio measures for grid-interactive efficient buildings as well as a measure for reporting and visualization.'
  spec.homepage      = 'https://github.com/LBNL-ETA/Openstudio-GEB-gem'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '3.2.2'

  spec.add_dependency 'openstudio-extension', '~> 0.8.3'
  spec.add_dependency 'openstudio-standards', '~> 0.7.1'
  spec.add_dependency 'simplecov', '0.22.0'

  spec.add_development_dependency 'rspec', '~> 3.9'

end
