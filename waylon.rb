require 'sinatra'
require 'date'
require 'jenkins_api_client'
require 'yaml'

class Waylon < Sinatra::Application
  get '/' do
    config = YAML.load(File.open('./waylon_config.yml'))

    # Refresh the page every `refresh_interval` seconds.
    refresh_interval = config['config'][0]['refresh_interval'].to_s

    # For each Jenkins instance in "jobs", connect to the server,
    # and get the status of the jobs specified in the config.
    filter          = []
    errors          = []
    failed_jobs     = []
    building_jobs   = []
    successful_jobs = []

    config['jobs'].each do |hash|
      hash.keys.each do |server|
        filter += hash[server] # job the job filter

        client = JenkinsApi::Client.new(:server_url => server)

        # Attempt to establish a connection to `server`
        begin
          client.get_root
        rescue SocketError
          errors << "Unable to connect to server: #{server}"
          next
        end

        # Get all the jobs and job details from the server. If the job
        # is in the job filter, check its status, and append it to the
        # relevant array.
        client.job.list_all_with_details.each do |job|
          if(filter.include?(job['name'])) then
            case client.job.color_to_status(job['color'])
            when 'running'
              building_jobs << job
            when 'failure'
              failed_jobs << job
            when 'success'
              successful_jobs << job
            end
          end
        end
      end
    end

    # If all jobs are green, display the image of the day. These images
    # are located in `public/img/` and follow the convention `imgNN.png`,
    # where NN is the day (number) of the week, starting with 0 (Sunday).
    if(failed_jobs.empty? and errors.empty?) then
      nirvana = true
      wday = Time.new.wday
      nirvana_img = "img/img0#{wday}.png"
    end

    erb :index,
      :locals => {
        :refresh_interval => refresh_interval,
        :nirvana          => nirvana,
        :nirvana_img      => nirvana_img,
        :errors           => errors,
        :failed_jobs      => failed_jobs,
        :building_jobs    => building_jobs,
        :successful_jobs  => successful_jobs,
    }
  end
end

