#!/usr/bin/env rake

task default: [:lint, :style]

# lint and style checks
desc 'Run FoodCritic (lint) tests'
task :lint do
  sh %(chef exec foodcritic --epic-fail any . --tags ~FC003)
end

desc 'Run RuboCop (style) tests'
task :style do
  sh %(chef exec rubocop)
end
