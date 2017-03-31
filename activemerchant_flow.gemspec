require_relative './lib/active_merchant/billing/gateways/flow.rb'

Gem::Specification.new 'activemerchant_flow' do |gem|
  gem.version     = ::ActiveMerchant::Billing::FlowGateway::VERSION
  gem.summary     = 'Adapter for Flow.io payment gateway'
  gem.description = 'Adapter for Flow.io payment gateway'
  gem.homepage    = 'https://www.flow.io'
  gem.license     = 'MIT'
  gem.authors     = ['Dino Reic']
  gem.email       = 'reic.dino@gmail.com'
  gem.files       = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files  = gem.files.grep(%r{spec/})

  gem.add_runtime_dependency 'active_merchant'
  gem.add_runtime_dependency 'flow-reference'
end