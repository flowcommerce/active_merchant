# @Flow.io (2017)
# Active Merchant adapter for Flow api

require 'flowcommerce-reference'

module ActiveMerchant
  module Billing
    class FlowGateway < Gateway
      VERSION = '0.1.3' unless defined?(::ActiveMerchant::Billing::FlowGateway::VERSION)

      self.display_name        = 'Flow.io Pay'
      self.homepage_url        = 'https://www.flow.io/'
      self.default_currency    = 'USD'
      self.supported_countries = FlowCommerce::Reference::Countries::ISO_3166_2
      self.supported_cardtypes = FlowCommerce::Reference::PaymentMethods::SUPPORTED_CREDIT_CARDS

      def initialize options = {}
        @flow_api_key      = options[:api_key]      || ENV['FLOW_API_KEY']
        @flow_organization = options[:organization] || ENV['FLOW_ORGANIZATION']

        raise ArgumentError, "Flow token is not defined (:api_key or ENV['FLOW_API_KEY'])" unless @flow_api_key
        raise ArgumentError, "Flow organization is not defined (:organization or ENV['FLOW_ORGANIZATION'])" unless @flow_organization

        super
      end

      # https://docs.flow.io/module/payment/resource/authorizations#post-organization-authorizations
      def authorize amount, payment_method, options={}
        amount = assert_currency options[:currency], amount

        response = get_flow_cc_token payment_method

        data = {
          token:    response.token,
          amount:   amount,
          currency: options[:currency],
          cvv:      payment_method.verification_value,
          customer: {
            name: {
              first: payment_method.first_name,
              last: payment_method.last_name
            }
          }
        }

        begin
          authorization_form = if options[:order_id]
              # order_number allready present at flow
              data[:order_number] = options[:order_id]
              ::Io::Flow::V0::Models::MerchantOfRecordAuthorizationForm.new data
            else
              ::Io::Flow::V0::Models::DirectAuthorizationForm.new data
            end

          response = flow_instance.authorizations.post @flow_organization, authorization_form
        rescue => exception
          return Response.new false, exception.message, { exception: exception }
        end

        options = { response: response }

        if ['review', 'authorized'].include?(response.result.status.value)
          store = {
                         key: response.key,
                      amount: response.amount,
                    currency: response.currency,
            authorization_id: response.id
          }

          Response.new true, 'Flow authorize - Success', options, { authorization: store }
        else
          Response.new false, 'Flow authorize - Error', options
        end
      end

      # https://docs.flow.io/module/payment/resource/captures#post-organization-captures
      def capture _money, authorization, options={}
        raise ArgumentError, 'No Authorization authorization, please authorize first' unless authorization

        begin
          capture_form = ::Io::Flow::V0::Models::CaptureForm.new authorization
          response     = flow_instance.captures.post @flow_organization, capture_form
        rescue => exception
          error_response exception
        end

        options = { response: response }

        if response.id
          Response.new true, 'Flow capture - Success', options
        else
          Response.new false, 'Flow capture - Error', options
        end
      end

      def purchase money, credit_card, options={}
        response = authorize money, credit_card, options
        capture money, response.authorization
      end

      # https://docs.flow.io/module/payment/resource/authorizations#delete-organization-authorizations-key
      def void money, authorization_key, options={}
        response = flow_instance.authorizations.delete_by_key @flow_organization, authorization_key
        Response.new true, 'void success', { response: response }
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response(exception)
      end

      # https://docs.flow.io/module/payment/resource/refunds
      # authorization_id - The Id of the authorization against which to issue the refund. If specified, we will look at all captures for this authorization, selecting 1 or more captures against which to issue the refund of the requested amount.
      # capture_id       - The Id of the capture against which to issue the refund. If specified, we will only consider this capture.
      # order_number     - The order number if specified during authorization. If specified, we will lookup all authorizations made against this order number, and then selecting 1 or more authorizations against which to issue the refund of the requested amount.
      # key              - Your unique identifier for this transaction, which if provided is used to implement idempotency. If not provided, we will assign.
      # amount           - The amount to refund, in the currency of the associated capture. Defaults to the value of the capture minus any prior refunds.
      # currency         - The ISO 4217-3 code for the currency. Required if amount is specified. Case insensitive. Note you will get an error if the currency does not match the related authrization's currency. See https://api.flow.io/reference/currencies
      # rma_key          - The RMA key, if available. If specified, this will udpate the RMA status as refunded.
      def refund amount, capture_id, options={}
        refund_form = {}
        refund_form[:amount]     = amount if amount
        refund_form[:capture_id] = capture_id if capture_id

        [:authorization_id, :currency, :order_number, :key, :rma_key].each do |key|
          refund_form[key] = options[key] if options[key]
        end

        if refund_form[:amount]
          raise ArgumentError, 'Currency is required if amount is provided' unless refund_form[:currency]
          refund_form[:amount] = assert_currency refund_form[:currency], refund_form[:amount]
        end

        refund_form = ::Io::Flow::V0::Models::RefundForm.new refund_form
        flow_instance.refunds.post @flow_organization, refund_form
      end

      # store credit card with flow and get reference token
      def store credit_card, options={}
        response = get_flow_cc_token credit_card
        Response.new true, 'Credit card stored', { response: response, token: response.token }
      rescue Io::Flow::V0::HttpClient::ServerError => exception
        error_response exception
      end

      private

      def flow_instance
        FlowCommerce.instance token: @flow_api_key
      end

      def get_flow_cc_token credit_card
        data = {    number: credit_card.number,
                      name: '%s %s' % [credit_card.first_name, credit_card.last_name],
                       cvv: credit_card.verification_value,
           expiration_year: credit_card.year.to_i,
          expiration_month: credit_card.month.to_i
        }

        card_form = ::Io::Flow::V0::Models::CardForm.new data
        flow_instance.cards.post @flow_organization, card_form
      end

      def error_response exception_object
        message = if exception_object.respond_to?(:body) && exception_object.body.length > 0
          description  = JSON.load(exception_object.body)['messages'].to_sentence
          '%s: %s (%s)' % [exception_object.details, description, exception_object.code]
        else
          exception_object.message
        end

        Response.new false, message, exception: exception_object
      end

      def assert_currency currency, amount
        raise ArgumentError, 'currency not provided' unless currency
        FlowCommerce::Reference::Currencies.find! currency
        amount.to_f
      end
    end
  end
end
