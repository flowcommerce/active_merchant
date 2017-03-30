require_relative './lib/active_merchant/billing/gateways/flow'

Gem::Specification.new 'activemerchant_flow' do |s|
  v.version     = ActiveMerchant::Billing::FlowGateway::VERSION
  s.description = 'Adapter for Flow.io payment gateway'
  s.authors     = ['Dino Reic']
  s.email       = 'reic.dino@gmail.com'
  s.files       = ['./lib/active_merchant/billing/gateways/flow.rb']
  s.homepage    = 'https://www.flow.io'
  s.license     = 'MIT'

  s.add_runtime_dependency 'active_merchant'
end