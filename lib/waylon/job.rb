class Waylon
  class Job

    attr_reader :name
    attr_reader :client
    attr_reader :job_details

    def initialize(name, client)
      @name   = name
      @client = client

      @job_details = {}
    end

    def query!
      @job_details = client.job.list_details(@name)
    end

    def status
      @client.job.color_to_status(@job_details['color'])
    end

    def est_duration
      # The values we need for getting progress and estimating time
      # remaining aren't available in jenkins_api_client's methods.
      # Luckily, api_get_request() is public and we can re-use our
      # existing connection.
      @client.api_get_request("/job/#{@name}/lastBuild", nil, "/api/json?depth=2&tree=estimatedDuration")['estimatedDuration']
    end

    def progress_pct
      last_build = client.api_get_request("/job/#{@name}/lastBuild", nil, "/api/json?depth=3")
      last_build['runs'].inject(0.0) do |accum, run|
        run_pct = (run['executor'] || {})['progress']

        accum = if run_pct == -1
                  -1
                elsif run_pct > accum
                  run_pct
                end
        accum
      end.tap do |x|
        require 'pry'
        binding.pry if x.nil?
      end
    rescue JenkinsApi::Exceptions::InternalServerError
      -1
    end

    def eta
      ## A build's 'duration' in the Jenkins API is only available
      ## after it has completed. Using estimatedDuration and the
      ## executor progress (in percentage), we can calculate the ETA.
      ## Note that estimatedDuration is returned in ms and here we
      ## convert it to seconds.

      #eta = (est_duration - (est_duration * (progress_pct / 100.0))) / 1000
      -1
    end

    def under_investigation?
      # Assume the job is in the failed state.

      last_build_descr = @client.job.get_build_details(@name, last_build_num)['description']

      !!(last_build_descr =~ /under investigation/i)
    end

    def last_build_num
      job_details['lastBuild']['number']
    end
  end
end
