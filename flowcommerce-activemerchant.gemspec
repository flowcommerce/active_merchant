require_relative 'lib/flowcommerce-activemerchant'

Gem::Specification.new 'flowcommerce-activemerchant' do |gem|
  gem.version     = ::ActiveMerchant::Billing::FlowGateway::VERSION
  gem.summary     = 'Adapter for Flow.io payment gateway'
  gem.description = 'Flow.io is PCI compliant gateway which supports authorizations, captures, refunds and tokenization of credit cards.'
  gem.homepage    = 'https://www.flow.io'
  gem.license     = 'MIT'
  gem.authors     = ['Dino Reic']
  gem.email       = 'tech@flow.io'
  gem.files       = Dir['./lib/**/*.rb']

  gem.add_runtime_dependency 'activemerchant', '~> 1.63'
  gem.add_runtime_dependency 'flowcommerce', '~> 0'
  gem.add_runtime_dependency 'flow-reference', '~> 0'
end