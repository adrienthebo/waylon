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
    failed_builds     = []
    successful_builds = []

    config['jobs'].each do |hash|
      hash.keys.each do |server|
        client = JenkinsApi::Client.new(:server_url => server)

        # list_by_status() gets an alphanumeric list of jobs based on the
        # friendly status returned by color_to_status(). We break this up
        # into two arrays: failed and successful. The failed builds will
        # display above the successful builds in the dashboard, in
        # alphanumeric order. If you want them to be displayed differently
        # (e.g. last-run at the top), take a look at list_details(job_name).
        # That approach is slightly more complicated though.
        failed_builds     += client.job.list_by_status('failure')
        successful_builds += client.job.list_by_status('success')
      end
    end

    # If all builds are green, display the image of the day. These images
    # are located in `public/img/` and follow the convention `imgNN.png`,
    # where NN is the day (number) of the week, starting with 0 (Sunday).
    wday = Time.new.wday
    if(failed_builds.empty?) then
      nirvana = true
      nirvana_img = "img/img0#{wday}.png"
    end

    erb :index,
      :locals => {
        :refresh_interval  => refresh_interval,
        :nirvana           => nirvana,
        :nirvana_img       => nirvana_img,
        :failed_builds     => failed_builds,
        :successful_builds => successful_builds,
    }
  end
end

