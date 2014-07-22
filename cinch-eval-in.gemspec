#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "cinch-eval-in"

  s.version = "0.0.1"

  s.summary = "A Cinch plug-in to evaluate Ruby code on https://eval.in."
  s.description = s.summary

  s.homepage = "http://github.com/Mon-Ouie/cinch-eval-in"

  s.email   = "mon.ouie@gmail.com"
  s.authors = ["Mon ouie"]

  s.files |= Dir["lib/**/*.rb"]
  s.files |= Dir["*.md"]
  s.files |= Dir["LICENSE"]

  s.license = "zlib"

  s.add_dependency "cinch", "~> 2.1"

  s.require_paths = %w[lib]
end
