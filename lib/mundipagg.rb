class Mundipagg
  attr_reader :validation_errors, :transaction, :error_message, :last_response, :masked_number, :instant_buy_key

  def initialize(options = {})
    @merchant_key = options[:merchant_key] || ENV['MUNDIPAGG_MERCHANT_KEY']
    @environment = options[:environment] || ENV['RACK_ENV'] || 'test'
    @validation_errors = []
  end

  def client
    @client ||= Savon.client(
      wsdl: 'https://transaction.mundipaggone.com/MundiPaggService.svc?wsdl',
      log: false,
      env_namespace: 'SOAP-ENV',
      namespace_identifier: :ns2,
      endpoint: "https://transaction.mundipaggone.com/MundiPaggService.svc",
      namespace: "http://tempuri.org/",
      namespaces: {
        'xmlns:ns1' => "http://schemas.datacontract.org/2004/07/MundiPagg.One.Service.DataContracts"
      },
      filters: ['MerchantKey'],
      pretty_print_xml: true,
      convert_request_keys_to: :camelcase,
      element_form_default: :qualified,
      encoding: 'UTF-8',
    )
  end

  def approve(params)
    if @approve_response = create_order(params)
      @last_response = @approve_response
      @masked_number = @approve_response[:credit_card_transaction_result_collection][:credit_card_transaction_result][:credit_card_number]
      @transaction = @approve_response[:order_key]
      @instant_buy_key = @approve_response[:credit_card_transaction_result_collection][:credit_card_transaction_result][:instant_buy_key]
      @error_message = approved? ? nil : @approve_response[:error_report].inspect
      return approved?
    else
      return false
    end
  end

  def approved?
    raise "Call this method after approve" if @approve_response.nil?
    @approve_response[:credit_card_transaction_result_collection][:credit_card_transaction_result][:success] == true
  end


  def create_order(params = {})
    raise "MerchantKey not configured. Set the environment variable MUNDIPAGG_MERCHANT_KEY or pass on initialization, ex: MundiPagg.new(merchant_key: 'key')." if @merchant_key.nil?
    using params do
      validates_presence_of 'AmountInCents'
      validates_numericality_of 'AmountInCents', :only_integer => true
      validates_inclusion_of 'CurrencyIsoEnum', in: %w( ARS BOB BRL CLP COP MXN PYG UYU EUR USD )
    end

    params['CreditCardTransactionCollection'] ||= {}
    params['CreditCardTransactionCollection']['CreditCardTransaction'] ||= []
    params['CreditCardTransactionCollection']['CreditCardTransaction'].each_with_index do |credit_card_transaction, i|
      using params['CreditCardTransactionCollection']['CreditCardTransaction'][i] do
        validates_presence_of 'CreditCardBrandEnum'
        validates_presence_of 'CreditCardNumber'
        validates_presence_of 'ExpMonth'
        validates_presence_of 'ExpYear'
        validates_presence_of 'HolderName'
        validates_presence_of 'InstallmentCount'
        validates_presence_of 'PaymentMethodCode'
        validates_presence_of 'SecurityCode'
        validates_inclusion_of 'CreditCardBrandEnum', in: %w( Visa Mastercard Hipercard Amex Diners Elo )
      end
    end
    return false unless @validation_errors.empty?
    message = "<ns2:createOrderRequest>#{Gyoku.xml(params, {
      :element_form_default => :qualified,
      :namespace            => :ns1,
      :key_converter        => :none
    })}</ns2:createOrderRequest>"
    response = client.call(:create_order, soap_action: "http://tempuri.org/MundiPaggService/CreateOrder", message: message)
    response.hash[:envelope][:body][:create_order_response][:create_order_result]
  end

  protected
    def using (params)
      @params = params
      yield
    end

    def validates_presence_of(field)
      value = @params[field]
      if value.nil?
        @validation_errors << {
          :field => field.to_sym,
          :message => :blank,
        }
      end
    end

    def validates_length_of(field, range_options)
      value = @params[field]
      return if value.nil?

      validity_checks = { :is => "==", :minimum => ">=", :maximum => "<=" }
      option = range_options.keys.first
      option_value = range_options[option]

      unless !value.nil? and value.size.method(validity_checks[option])[option_value]
        @validation_errors << {
          :field => field,
          :message => {:is => :wrong_length, :minimum => :too_short, :maximum => :too_long}[option],
        }
      end
    end

    def validates_numericality_of(field, configuration = {})
      value = @params[field]
      return if value.nil?

      if configuration[:only_integer]
        unless value.to_s =~ /\A[+-]?\d+\Z/
          @validation_errors << {
            :field => field,
            :message => :not_a_number,
          }
        end
      else
        begin
          value = Kernel.Float(value)
        rescue ArgumentError, TypeError
          @validation_errors << {
            :field => field,
            :message => :not_a_number,
          }
        end
      end
    end

    def validates_inclusion_of(field, configuration)
      value = @params[field]
      return if value.nil?

      enum = configuration[:in] || configuration[:within]
      unless enum.include?(value)
        @validation_errors << {
          :field => field,
          :message => :inclusion,
        }
      end
    end

=begin
def cap(params = {})
@params = params
validates_presence_of :NumeroDocumento if @params[:Transacao].nil?
validates_presence_of :Transacao if @params[:NumeroDocumento].nil?
return {"ErroValidacao" => @errors} unless @errors.empty?

raise "You should set cap_url variable in configuration file with correct CAP URL" if config["cap_url"].nil?
ret = do_post(config["cap_url"], @params)
{"ErroValidacao" => nil}.merge(ret)
end

def can(params = {})
@params = params
validates_presence_of :NumeroDocumento if @params[:Transacao].nil?
validates_presence_of :Transacao if @params[:NumeroDocumento].nil?
return {"ErroValidacao" => @errors} unless @errors.empty?

raise "You should set can_url variable in configuration file with correct CAN URL" if config["can_url"].nil?
ret = do_post(config["can_url"], @params)
{"ErroValidacao" => nil}.merge(ret)
end

def do_post(url, params)
response = Net::HTTP.post_form(URI.parse(url), params)
ret = XmlSimple.xml_in(response.body, { "keeproot" => false, "forcearray" => false })
ret.strip_values! unless ret.nil?
end

def approve(params)
@apc_response = apc(params)
@last_response = @apc_response
@transaction = @apc_response["Transacao"]
@error_message = approved? ? nil : @apc_response["ResultadoSolicitacaoAprovacao"]
return approved?
end

def confirm(params)
@cap_response = cap(params)
@last_response = @cap_response
@error_message = confirmed? ? nil : (cgi_mode? ? @cap_response["ResultadoSolicitacaoAprovacao"] : @cap_response["ResultadoSolicitacaoConfirmacao"])
return confirmed?
end

def cancel(params)
raise "Method not available in cgi mode" if cgi_mode?

@can_response = can(params)
@last_response = @can_response
@error_message = (cancelled? or to_cancel?) ? nil : @can_response["ResultadoSolicitacaoCancelamento"]
return(cancelled? or to_cancel?)
end

def approved?
raise "Call this method after approve" if @apc_response.nil?
@apc_response["TransacaoAprovada"].upcase == "TRUE"
end

def confirmed?
raise "Call this method after confirm" if @cap_response.nil?

result = (cgi_mode? ? @cap_response["ResultadoSolicitacaoAprovacao"] : @cap_response["ResultadoSolicitacaoConfirmacao"])
result =~ /Confirmado/
end

def cancelled?
raise "Call this method after cancel" if @can_response.nil?
result = @can_response["ResultadoSolicitacaoCancelamento"]
result =~ /Cancelado/
end

def to_cancel?
raise "Call this method after cancel" if @can_response.nil?
result = @can_response["ResultadoSolicitacaoCancelamento"]
result.gsub('%20', ' ') =~ /Cancelamento marcado para envio/
end

def error?
!@error_message.nil?
end

def cgi_mode?
config['mode'] == 'cgi'
end
=end

end