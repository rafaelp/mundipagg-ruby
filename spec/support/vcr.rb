require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<MUNDIPAGG_MERCHANT_KEY>') do |interaction|
    ENV['MUNDIPAGG_MERCHANT_KEY']
  end
end