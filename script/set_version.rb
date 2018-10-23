#!/usr/bin/env ruby

# Sets the VERSION constant based on latest git tag

require 'pathname'

def die info
  puts info
  exit 1
end

version_file = Pathname.new('./.version')

unless version_file.exist?
  die "ERROR: File '%s' not found" % version_file
end

current_version = version_file.read.chomp
next_version = `sem-info tag next`.strip

if current_version == next_version
  die "File #{version_file} already points to latest version: #{next_version}"
end

version_file.write next_version

system "git commit -m 'Update version to #{next_version}'"
system "git push"

puts "Updated #{version_file} to latest version: #{next_version}"

