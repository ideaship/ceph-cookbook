#!/usr/bin/env rake

task default: [:lint, :style]

# lint and style checks
desc 'Run FoodCritic (lint) tests'
task :lint do
  sh %(chef exec foodcritic --epic-fail any . -t ~FC003 -t ~FC075)
end

desc 'Run cookstyle tests'
task :style do
  sh %(chef exec cookstyle)
end
