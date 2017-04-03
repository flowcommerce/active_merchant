require_relative 'lib/activemerchant_flow'

Gem::Specification.new 'activemerchant_flow' do |gem|
  gem.version     = ::ActiveMerchant::Billing::FlowGateway::VERSION
  gem.summary     = 'Adapter for Flow.io payment gateway'
  gem.description = 'Adapter for Flow.io payment gateway'
  gem.homepage    = 'https://www.flow.io'
  gem.license     = 'MIT'
  gem.authors     = ['Dino Reic']
  gem.email       = 'reic.dino@gmail.com'
  gem.files       = Dir['./lib/**/*.rb']

  gem.add_runtime_dependency 'activemerchant'
  gem.add_runtime_dependency 'flowcommerce'
  gem.add_runtime_dependency 'flow-reference'
end