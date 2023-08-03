# TODO
module Wault
  require 'yaml'
  require 'chronic_duration'
  require 'vault'

  # TODO
  class Data
    attr_accessor :name

    def initialize(cache, name, params, scope)
      # Требуемые параметры
      @cache_hash = cache.retrieve(self)
      @name = name
      @params = params
      @scope = scope
      @default_fact = '__common' # kv/__common/<name>

      # Параметры для настройки Wault
      @config_dir  = params['config_dir'] || '/opt/wault'
      @config_file = params['config_file'] || "#{@config_dir}/.vault.yaml"
      @path        = params['path'] || nil
      @namespace   = params['namespace'] || nil
      @force       = params['force'] || false
      @address     = params['address'] || yaml['address']
      @token       = params['token'] || yaml['token']
      @ssl_verify  = params['ssl_verify'] || yaml.fetch('ssl_verify', false)
      @timeout     = params['timeout'] || yaml.fetch('timeout', 30)

      # Параметры для внутреннего использования
      @stale = {}

      configure
      staled
    end

    def path
      return "kv/#{real_facts}/#{name}" if @path.nil?

      @path
    end

    def staled
      result = get_value
      return {} unless result.is_a? Hash

      @stale[:password] = result[:value]
      @stale[:expire] = result[:expire].to_i if result[:expire].to_i > 0
      @stale[:expire_duration] = result[:expire_duration]
    end

    def sync
      return censure(@stale[:password]) unless need_replace?

      Vault.with_retries(Vault::HTTPConnectionError) do
        Vault.logical.write(path, value: value,
                            expire: real_expire ? Time.now.to_i + real_expire : real_expire,
                            expire_duration: expire, ttl: real_expire)
        censure(value)
      end
    end

    def censure(input)
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(input)
    end

    def need_replace?
      # Not password || expired || changed duration
      !@stale.key? :password or key_expired? or @stale[:expire_duration] != expire
    end

    def key_expired?
      @stale[:expire] ? Time.now.to_i > @stale[:expire] : false
    end

    def get_value
      cache_key = [@name, @address, @namespace]
      last_result = @cache_hash[cache_key]
      return last_result unless (last_result.nil? or @force)
      value = Vault.logical.read(path)
      return nil unless value

      data = value.data
      censured_data = data
      @cache_hash[cache_key] = censured_data

      censured_data
    end

    def configure
      yaml.each do |key, value|
        Vault.client.instance_variable_set(:"@#{key}", value)
      end
      Vault.client.instance_variable_set(:"@namespace", @namespace) unless @namespace.nil?
    end

    def yaml
      YAML.load_file(@config_file)
    end

    def value
      # Puppet::Pops::Types::PSensitiveType::Sensitive.new
      @params['value'] = generate unless @params.key? 'value'

      @params.fetch('value')
    end

    def expire
      return '' unless @params.key? 'expire'

      @params.fetch('expire')
    end

    def facts
      @params.fetch('facts', @default_fact)
    end

    def generate
      SecureRandom.base64 14
    end

    def real_facts
      return facts unless facts.is_a? Array

      gen_facts.join('/')
    end

    def gen_facts
      facts.sort.map { |f| "#{f}__#{facter(f)}" }
    end

    def real_expire
      ChronicDuration.parse(expire)
    end

    def facter(name)
      return @scope[name] if @scope.key? name

      Facter.value(name)
    end
  end
end

Puppet::Functions.create_function(:'wault::data', Puppet::Functions::InternalFunction) do
  dispatch :run do
    cache_param
    required_param 'String', :name
    optional_param 'Hash', :params
  end

  def run(cache, name, params = {})
    pass = Wault::Data.new(cache, name, params, closure_scope)
    pass.sync
  end
end
