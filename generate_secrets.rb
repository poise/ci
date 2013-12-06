#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'base64'
require 'digest'
require 'openssl'
require 'securerandom'

class JenkinsSecrets
  MAGIC = '::::MAGIC::::'
  attr_accessor :master_key, :secrets_key, :token

  def initialize
    generate_master_key
    generate_secrets_key
    generate_token
  end

  def generate_master_key
    # https://github.com/jenkinsci/jenkins/blob/48efa739c7d6c2b68ea66f64c1b41124af54aba3/core/src/main/java/jenkins/security/DefaultConfidentialStore.java#L63
    @master_key = SecureRandom.hex(128)
  end

  def generate_secrets_key
    # https://github.com/jenkinsci/jenkins/blob/48efa739c7d6c2b68ea66f64c1b41124af54aba3/core/src/main/java/jenkins/security/CryptoConfidentialKey.java#L34
    @secrets_key = SecureRandom.random_bytes(256)
  end

  def generate_token
    # https://github.com/jenkinsci/jenkins/blob/48efa739c7d6c2b68ea66f64c1b41124af54aba3/core/src/main/java/jenkins/security/ApiTokenProperty.java#L90
    @token = SecureRandom.hex(16)
  end

  def encrypt_secrets_key
    clear_text = @secrets_key + MAGIC
    encryptor = OpenSSL::Cipher.new('AES-128-ECB')
    encryptor.encrypt
    encryptor.key = Digest::SHA256.digest(@master_key)[0..15]
    encryptor.update(clear_text) + encryptor.final()
  end

  def encrypt_token
    clear_text = @token + MAGIC
    encryptor = OpenSSL::Cipher.new('AES-128-ECB')
    encryptor.encrypt
    encryptor.key = @secrets_key[0..15]
    cipher_text = encryptor.update(clear_text) + encryptor.final()
    Base64::strict_encode64(cipher_text)
  end

  def hashed_token
    Digest::MD5.hexdigest(@token)
  end

  def write_secrets
    Dir.mkdir('secrets') unless File.exists?('secrets')
    Dir.mkdir('secrets/jenkins_master') unless File.exists?('secrets/jenkins_master')
    Dir.mkdir('secrets/jenkins_builder') unless File.exists?('secrets/jenkins_builder')
    if File.exists?('secrets/jenkins_master/master.key')
      puts "master.key already exists, cowardly refusing to overwrite it"
      return
    end
    File.open('secrets/jenkins_master/master.key', 'wb') do |f|
      f.write(@master_key)
    end
    File.open('secrets/jenkins_master/hudson.util.Secret', 'wb') do |f|
      f.write(encrypt_secrets_key)
    end
    File.open('secrets/jenkins_master/apiToken', 'wb') do |f|
      f.write(encrypt_token)
    end
    File.open('secrets/jenkins_builder/hashedToken', 'wb') do |f|
      f.write(hashed_token)
    end
  end

  def generate_ssh_keys
    if File.exists?('secrets/jenkins_builder/id_rsa')
      puts "id_rsa already exists, cowardly refusing to overwrite it"
      return
    end
    `ssh-keygen -f secrets/jenkins_builder/id_rsa -N ''`
    File.rename('secrets/jenkins_builder/id_rsa.pub', 'secrets/jenkins_master/id_rsa.pub')
  end

  # Used to verify I know what I'm doing, this is the code that was originally
  # reverse enginered from existing Jenkins credentials.
  def decrypt_token(master, secret, token)
    # Decrypt the key for hudson.util.Secret
    decryptor = OpenSSL::Cipher.new('AES-128-ECB')
    decryptor.decrypt
    decryptor.key = Digest::SHA256.digest(master)[0..15]
    ct = decryptor.update(secret) + decryptor.final()
    # Strip the magic suffix
    raise "Bad magic suffix" unless ct.end_with?(MAGIC)
    ct = ct[0..-1-MAGIC.length]
    # Decrypt the raw token
    decryptor = OpenSSL::Cipher.new('AES-128-ECB')
    decryptor.decrypt
    decryptor.key = ct[0..15]
    ct = decryptor.update(Base64::decode64(token)) + decryptor.final()
    # Strip the magic suffix, again
    raise "Bad magic suffix" unless ct.end_with?(MAGIC)
    ct = ct[0..-1-MAGIC.length]
    # The final key is an MD5 of this text
    Digest::MD5.hexdigest(ct)
  end
end

s = JenkinsSecrets.new
raise "Sanity check failed" unless s.decrypt_token(s.master_key, s.encrypt_secrets_key, s.encrypt_token) == s.hashed_token
s.write_secrets
s.generate_ssh_keys
