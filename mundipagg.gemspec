# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mundipagg"
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Rafael Lima"]
  s.date = "2014-01-06"
  s.description = "Biblioteca Ruby para utilizacao do sistema MundiPagg"
  s.email = "contato@rafael.adm.br"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.mkdn"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.mkdn",
    "Rakefile",
    "VERSION",
    "lib/mundipagg.rb",
    "mundipagg.gemspec"
  ]
  s.homepage = "http://github.com/rafaelp/mundipagg-ruby"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Ruby wrapper for MundiPagg"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<savon>, ["= 2.2.0"])
      s.add_development_dependency(%q<rspec>, ["= 2.3.0"])
      s.add_development_dependency(%q<vcr>, ["= 2.4.0"])
      s.add_development_dependency(%q<webmock>, ["= 1.8.0"])
      s.add_development_dependency(%q<bundler>, ["= 1.3.5"])
      s.add_development_dependency(%q<jeweler>, ["= 1.8.4"])
      s.add_development_dependency(%q<pry>, ["= 0.9.12.1"])
      s.add_development_dependency(%q<awesome_print>, ["= 1.1.0"])
      s.add_development_dependency(%q<dotenv>, ["= 0.7.0"])
    else
      s.add_dependency(%q<savon>, ["= 2.2.0"])
      s.add_dependency(%q<rspec>, ["= 2.3.0"])
      s.add_dependency(%q<vcr>, ["= 2.4.0"])
      s.add_dependency(%q<webmock>, ["= 1.8.0"])
      s.add_dependency(%q<bundler>, ["= 1.3.5"])
      s.add_dependency(%q<jeweler>, ["= 1.8.4"])
      s.add_dependency(%q<pry>, ["= 0.9.12.1"])
      s.add_dependency(%q<awesome_print>, ["= 1.1.0"])
      s.add_dependency(%q<dotenv>, ["= 0.7.0"])
    end
  else
    s.add_dependency(%q<savon>, ["= 2.2.0"])
    s.add_dependency(%q<rspec>, ["= 2.3.0"])
    s.add_dependency(%q<vcr>, ["= 2.4.0"])
    s.add_dependency(%q<webmock>, ["= 1.8.0"])
    s.add_dependency(%q<bundler>, ["= 1.3.5"])
    s.add_dependency(%q<jeweler>, ["= 1.8.4"])
    s.add_dependency(%q<pry>, ["= 0.9.12.1"])
    s.add_dependency(%q<awesome_print>, ["= 1.1.0"])
    s.add_dependency(%q<dotenv>, ["= 0.7.0"])
  end
end

