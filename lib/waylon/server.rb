require 'jenkins_api_client'

class Waylon
  class Server
    require 'waylon/job'

    attr_reader :name
    attr_reader :url
    attr_reader :username
    attr_reader :password

    attr_reader :jobs

    attr_reader :client

    def self.from_hash(name, values)
      o = new(name, values['url'], values['username'], values['password'])
      (values['jobs'] || []).each do |job|
        o.add_job(job)
      end
      o
    end

    def initialize(name, url, username, password)
      @name = name
      @url = url
      @username = username
      @password = password
      @client   = JenkinsApi::Client.new(:server_url => @url,
                                         :username   => @username,
                                         :password   => @password)

      @jobs = []
    end

    def add_job(name)
      @jobs << Waylon::Job.new(name, client)
    end

    def verify_client!
      @client.get_root  # Attempt a connection to `server`
    end
  end
end
