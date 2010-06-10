# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{scratchpad}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["costan"]
  s.date = %q{2010-06-10}
  s.description = %q{Proof-of-concept models for a system that trusts an FPGA and a smart-card chip
for integrity verification of an untrusted storage medium.
}
  s.email = %q{victor@costan.us}
  s.executables = ["enable_pcap", "ether_ping", "ether_ping_server"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     ".project",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/enable_pcap",
     "bin/ether_ping",
     "bin/ether_ping_server",
     "lib/scratchpad.rb",
     "lib/scratchpad/common/crypto.rb",
     "lib/scratchpad/common/hash_tree.rb",
     "lib/scratchpad/common/hash_tree_cache.rb",
     "lib/scratchpad/common/hash_tree_cache_driver.rb",
     "lib/scratchpad/dev_keys/manufacturer.crt",
     "lib/scratchpad/dev_keys/manufacturer.key.der",
     "lib/scratchpad/dev_keys/manufacturer.yml",
     "lib/scratchpad/ethernet/ping.rb",
     "lib/scratchpad/ethernet/raw_ethernet.rb",
     "lib/scratchpad/models/client.rb",
     "lib/scratchpad/models/disk.rb",
     "lib/scratchpad/models/fpga.rb",
     "lib/scratchpad/models/manufacturer.rb",
     "lib/scratchpad/models/server.rb",
     "lib/scratchpad/models/smartcard.rb",
     "scratchpad.gemspec",
     "test/disk_test.rb",
     "test/hash_tree_cache_driver_test.rb",
     "test/hash_tree_cache_test.rb",
     "test/hash_tree_test.rb",
     "test/helper.rb",
     "test/integration_test.rb",
     "test/manufacturer_test.rb"
  ]
  s.homepage = %q{http://github.com/costan/scratchpad}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{High-performance trusted cloud storage proof-of-concept}
  s.test_files = [
    "test/disk_test.rb",
     "test/hash_tree_cache_test.rb",
     "test/manufacturer_test.rb",
     "test/integration_test.rb",
     "test/helper.rb",
     "test/hash_tree_test.rb",
     "test/hash_tree_cache_driver_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<fakefs>, [">= 0.2.1"])
      s.add_development_dependency(%q<jeweler>, [">= 1.4.0"])
      s.add_runtime_dependency(%q<ffi>, [">= 0.6.3"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
    else
      s.add_dependency(%q<fakefs>, [">= 0.2.1"])
      s.add_dependency(%q<jeweler>, [">= 1.4.0"])
      s.add_dependency(%q<ffi>, [">= 0.6.3"])
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    end
  else
    s.add_dependency(%q<fakefs>, [">= 0.2.1"])
    s.add_dependency(%q<jeweler>, [">= 1.4.0"])
    s.add_dependency(%q<ffi>, [">= 0.6.3"])
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
  end
end

