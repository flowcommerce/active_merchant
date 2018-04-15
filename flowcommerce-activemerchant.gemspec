require_relative 'lib/flowcommerce-activemerchant'

Gem::Specification.new do |gem|
  gem.name        = 'flowcommerce-activemerchant'
  gem.version     = ::ActiveMerchant::Billing::FlowGateway::VERSION
  gem.summary     = 'Adapter for Flow.io global payment gateway'
  gem.description = 'Flow.io is PCI compliant gateway which supports authorizations, captures, refunds and tokenization of credit cards globally.'
  gem.homepage    = 'https://www.flow.io'
  gem.license     = 'MIT'
  gem.authors     = ['Dino Reic']
  gem.email       = 'tech@flow.io'
  gem.files       = Dir['./lib/**/*.rb']

  gem.add_runtime_dependency 'activemerchant', '~> 1.78'
  gem.add_runtime_dependency 'flowcommerce', '~> 0.2.58'
  gem.add_runtime_dependency 'flow-reference', '~> 0.3.2'
end
