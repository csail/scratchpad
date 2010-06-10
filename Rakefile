require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "scratchpad"
    gem.summary = %Q{High-performance trusted cloud storage proof-of-concept}
    gem.description = <<END
Proof-of-concept models for a system that trusts an FPGA and a smart-card chip
for integrity verification of an untrusted storage medium.
END
    gem.email = "victor@costan.us"
    gem.homepage = "http://github.com/costan/scratchpad"
    gem.authors = ["costan"]
    gem.add_development_dependency "fakefs", ">=0.2.1"
    gem.add_development_dependency "jeweler",  ">=1.4.0"
    gem.add_runtime_dependency "ffi", ">=0.6.3"
    gem.add_runtime_dependency "eventmachine", ">=0.12.10"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "scratchpad #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
