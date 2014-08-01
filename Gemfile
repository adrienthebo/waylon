source ENV['GEM_SOURCE'] || 'https://rubygems.org'

ruby '2.1.1'
gem 'sinatra',            '~> 1.4.5'
gem 'unicorn',            '~> 4.8.3'
gem 'jenkins_api_client', '~> 0.14.1'
gem 'deterministic'

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
