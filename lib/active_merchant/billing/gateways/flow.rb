# @Flow.io (2017)
# Active Merchant adapter for Flow api

module ActiveMerchant
  module Billing
    class FlowGateway < Gateway

      self.display_name     = 'Flow.io Pay'
      self.homepage_url     = 'https://www.flow.io/'
      self.default_currency = 'USD'

      def initialize(options = {})
        @flow_api_key      = options[:api_key]      || ENV['FLOW_API_KEY']
        @flow_organization = options[:organization] || ENV['FLOW_ORGANIZATION']

        raise ArgumentError, "Flow token is not defined (:apy_key or ENV['FLOW_API_KEY'])" unless @flow_api_key
        raise ArgumentError, "Flow organization is not defined (:organization or ENV['FLOW_ORGANIZATION'])" unless @flow_organization

        super
      end

      def authorize(amount, payment_method, options={})
        get_flow_cc_token payment_method

        data = {
          token:    @flow_cc_token,
          amount:   (amount / 100.0).round(2),
          currency: options[:currency] || self.default_currency,
          cvv:      payment_method.verification_value,
          customer: {
            name: {
              first: payment_method.first_name,
              last: payment_method.last_name
            }
          }
        }

        begin
          direct_authorization_form = ::Io::Flow::V0::Models::DirectAuthorizationForm.new(data)
          response = flow_instance.authorizations.post(@flow_organization, direct_authorization_form)
        rescue => exception
          return Response.new(false, ex.message, { exception: exception })
        end

        options = { response: response }

        if response.result.status.value == 'authorized'
          # what store this in spree order object, for capure
          store = {}
          store[:authorization_id] = response.id
          store[:currency]         = response.currency
          store[:amount]           = response.amount
          store[:key]              = response.key

          @flow_authorization = store

          Response.new(true, 'Flow authorize - Success', options, { authorization: store })
        else
          Response.new(false, 'Flow authorize - Error', options)
        end
      end

      def store(object, options={})
        Response.new(true)
      end

      def capture(_money, authorization, options={})
        raise ArgumentError, 'No Authorization authorization, please authorize first' unless authorization

        begin
          capture_form = ::Io::Flow::V0::Models::CaptureForm.new(authorization)
          response     = flow_instance.captures.post(@flow_organization, capture_form)
        rescue => exception
          error_response(exception)
        end

        options = { response: response }

        if response.id
          Response.new(true, 'Flow capture - Success', options)
        else
          Response.new(false, 'Flow capture - Error', options)
        end
      end

      def void(money, authorization_key, options={})
        # authorization_key ||= @flow_authorization[:key]
        begin
          flow_instance.authorizations.delete_by_key(@flow_organization, authorization_key)
          Response.new(true, 'success')
        rescue Io::Flow::V0::HttpClient::ServerError => exception
          error_response(exception)
        end
      end

      def purchase(money, credit_card, options={})
        response = authorize money, credit_card
        capture money, response.authorization
      end

      #  def refund(money, authorization, options={})
      #  end

      private

      def flow_instance
        FlowCommerce.instance(token: @flow_api_key)
      end

      def get_flow_cc_token(credit_card)
        return if @flow_cc_token

        data = {}
        data[:number]           = credit_card.number
        data[:name]             = '%s %s' % [credit_card.first_name, credit_card.last_name]
        data[:cvv]              = credit_card.verification_value
        data[:expiration_year]  = credit_card.year.to_i
        data[:expiration_month] = credit_card.month.to_i

        card_form = ::Io::Flow::V0::Models::CardForm.new(data)
        result    = flow_instance.cards.post(@flow_organization, card_form)

        @flow_cc_token = result.token
      end

      def error_response(exception_object, message=nil)
        message ||= exception_object.message
        Response.new(false, message, exception: exception_object)
      end
    end
  end
end