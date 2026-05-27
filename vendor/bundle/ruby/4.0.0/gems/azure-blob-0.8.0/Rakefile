# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "azure_blob"
require_relative "test/support/app_service_vpn"
require_relative "test/support/azure_vm_vpn"
require_relative "test/support/aks_vpn"
require_relative "test/support/azurite"

Minitest::TestTask.create(:test_rails) do
  self.test_globs = [ "test/rails/**/test_*.rb",
                     "test/rails/**/*_test.rb", ]
end

Minitest::TestTask.create(:test_client) do
  self.test_globs = [ "test/client/**/test_*.rb",
                     "test/client/**/*_test.rb", ]
end

task default: %i[test]

task :test do
  [
    "AZURE_ACCOUNT_NAME",
    "AZURE_PRIVATE_CONTAINER",
    "AZURE_PUBLIC_CONTAINER",
  ].each do |env|
    value = ENV[env]
    raise "#{env} variable need to be set if you are using the nix/devenv environment, consider running generate-env-file" if value.nil? || value.empty?
  end

  Rake::Task["test_client"].execute
  Rake::Task["test_rails"].execute
end

task :test_app_service do |t|
  vpn = AppServiceVpn.new
  ENV["IDENTITY_ENDPOINT"] = vpn.endpoint
  ENV["IDENTITY_HEADER"] = vpn.header
  Rake::Task["test_entra_id"].execute
ensure
  vpn.kill
end

task :test_azure_vm do |t|
  vpn = AzureVmVpn.new
  Rake::Task["test_entra_id"].execute
ensure
  vpn.kill
end

task :test_aks do |t|
  vpn = AksVpn.new
  ENV["AZURE_CLIENT_ID"] = vpn.client_id
  ENV["AZURE_TENANT_ID"] = vpn.tenant_id
  ENV["AZURE_FEDERATED_TOKEN_FILE"] = vpn.token_file
  Rake::Task["test_entra_id"].execute
ensure
  vpn.kill
end

task :test_azurite do |t|
  azurite = Azurite.new
  # Azurite well-known credentials
  # https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azurite?tabs=visual-studio%2Cblob-storage#well-known-storage-account-and-key
  account_name = ENV["AZURE_ACCOUNT_NAME"] = "devstoreaccount1"
  access_key = ENV["AZURE_ACCESS_KEY"] = "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
  host = ENV["STORAGE_BLOB_HOST"] = "http://127.0.0.1:10000/devstoreaccount1"
  ENV["TESTING_AZURITE"] = "true"

  # Create containers
  private_container = AzureBlob::Client.new(account_name:, access_key:, host:, container: ENV["AZURE_PRIVATE_CONTAINER"])
  public_container = AzureBlob::Client.new(account_name:, access_key:, host:, container: ENV["AZURE_PUBLIC_CONTAINER"])
  # public_container.delete_container
  private_container.create_container unless private_container.get_container_properties.present?
  public_container.create_container(public_access: true) unless public_container.get_container_properties.present?

  Rake::Task["test_client"].execute
  Rake::Task["test_rails"].execute
ensure
  azurite.kill
end

task :test_entra_id do |t|
  ENV["AZURE_ACCESS_KEY"] = nil
  Rake::Task["test"].execute
end

task :flush_test_container do |t|
  AzureBlob::Client.new(
    account_name: ENV["AZURE_ACCOUNT_NAME"],
    access_key: ENV["AZURE_ACCESS_KEY"],
    container: ENV["AZURE_PRIVATE_CONTAINER"],
  ).delete_prefix ""
  AzureBlob::Client.new(
    account_name: ENV["AZURE_ACCOUNT_NAME"],
    access_key: ENV["AZURE_ACCESS_KEY"],
    container: ENV["AZURE_PUBLIC_CONTAINER"],
  ).delete_prefix ""
end
