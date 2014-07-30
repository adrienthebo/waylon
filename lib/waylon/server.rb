class Waylon
  class Server
    attr_reader :url
    attr_reader :username
    attr_reader :password

    attr_reader :jobs

    def self.from_hash(url, values)
      o = new(url, values['username'], values['password'])
      values['jobs'].each do |job|
        o.jobs << job
      end
      o
    end

    def initialize(url, username, password)
      @url = url
      @username = username
      @password = password

      @jobs = []
    end
  end
end
