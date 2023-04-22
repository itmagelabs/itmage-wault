#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'fileutils'

# Описание
#
# Это скрипт для инициализации тестового стенда Vault.
# Не рекомендуется использовать скрипт для боевого окружения.
#
# plan bolt_project::run_init_vault (
#   TargetSpec $targets = "localhost"
# ) {
#   $command_result = run_task('wault', $targets)
#   return $command_result
# }
#
class HashicoprObj
  attr_accessor :path, :addr, :cmd

  def initialize(path: '/root/acl-token-bootstrap-vault.json')
    @path = path
    @config_dir = '/opt/wault'
    @config_file = "#{@config_dir}/.vault.yaml"
    @addr = 'http://127.0.0.1:8200'
    @cmd  = ['/usr/bin/vault']
  end

  def run(cmd)
    ENV['VAULT_TOKEN'] = root_token
    ENV['VAULT_ADDR'] = @addr
    `#{cmd}`
  end

  def unseal
    unseal_keys_b64.each do |key|
      run_unseal key
    end
  end

  def run_unseal(key, cmd = @cmd.dup)
    cmd << 'operator unseal'
    cmd << '-non-interactive=true'
    cmd << '-format=json'
    cmd << key
    run cmd.join(' ')
  end

  def create_kv(version = 1, cmd = @cmd.dup)
    cmd << 'secrets enable'
    cmd << '-non-interactive=true'
    cmd << "-version=#{version} kv"
    run cmd.join(' ') unless kv? 'kv/'
  end

  def node_config
    FileUtils.mkdir_p @config_dir unless Dir.exist? @config_dir
    config_hash = {
      address: @addr,
      token: root_token,
      ssl_verify: false,
      timeout: 30
    }
    File.write(@config_file, config_hash.to_yaml)
  end

  def kv?(path, cmd = @cmd.dup)
    cmd << 'secrets list -format=json'
    out = run cmd.join(' ')
    return true if JSON.parse(out).key? path

    false
  end

  def file
    File.read(@path)
  end

  def hash
    JSON.parse(file)
  end

  def unseal_keys_b64
    hash['unseal_keys_b64'] if File.readable?(@path)
  end

  def root_token
    hash['root_token'] if File.readable?(@path)
  end
end

vault = HashicoprObj.new
vault.unseal
vault.create_kv
vault.node_config
