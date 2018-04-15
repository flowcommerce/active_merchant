#!/usr/bin/env ruby

# Sets the VERSION constant based on latest git tag

path = "lib/active_merchant/billing/gateways/flow.rb"
file = File.join(File.dirname(__FILE__), "../#{path}")

if !File.exists?(file)
  puts "ERROR: File '%s' not found" % file
  exit(1)
end

next_version = `sem-info tag next`.strip

found = modified = false
lines = IO.readlines(file).map do |l|
  if md = l.match(/VERSION = '(\d+\.\d+\.\d+)'/)
    if found
      puts "ERROR: File '%s' contains duplicate VERSION constants" % file
      exit(1)
    end

    found = true
    if md[1] == next_version
      l
    else
      modified = true
      l.sub(/(VERSION = '\d+\.\d+\.\d+')/, "VERSION = '#{next_version}'")
    end
  else
    l
  end
end

if !found
  puts "ERROR: File '%s': Could not find VERSION" % file
  exit(1)
end

if modified
  File.open(file, 'w') { |out| out << lines.join("") }
  cmd = "git commit -m 'Update version to #{next_version}' #{path}"
  system(cmd)
  cmd = "git push"
  system(cmd)
  puts "Updated #{path} to latest version: #{next_version}"
else
  puts "File #{path} already points to latest version: #{next_version}"
end
