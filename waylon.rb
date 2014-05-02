require 'sinatra'
require 'date'
require 'jenkins_api_client'
require 'yaml'

class Waylon < Sinatra::Application
  helpers do

    # escape() sanitizes text for use as a URL
    def escape(text)
      Rack::Utils.escape(text)
    end

    # get_views() does just that, gets a list of views.
    def get_views()
      config = YAML.load_file(File.join(File.dirname(__FILE__), 'waylon_config.yml'))
      views = []
      config['views'].each do |view|
        views += view.keys
      end
      return views
    end

    # weather() returns an img src, alt, and title, based on build stability
    def weather(score)
      case score.to_i
      when 100
        {
          'src' => '../img/sun.png',
          'alt' => '[sun]',
          'title' => 'No recent builds failed'
        }
      when 80
        {
          'src' => '../img/cloud.png',
          'alt' => '[cloud]',
          'title' => '1 of the last 5 builds failed'
        }
      else
        {
          'src' => '../img/umbrella.png',
          'alt' => '[umbrella]',
          'title' => '2 or more of the last 5 builds failed'
        }
      end
    end

  end

  # Landing page (index.html)
  # Print a list of views available on this Waylon instance.
  get '/' do
    views = get_views()
    erb :index, :locals => { :views => views }
  end

  # Individual views (view/foo)
  # When navigating to 'view/foo', queries waylon_config.yml for
  # that view's config (servers to connect to, and jobs to display).
  get '/view/:name' do
    this_view = Rack::Utils.unescape(params[:name])
    config = YAML.load_file(File.join(File.dirname(__FILE__), 'waylon_config.yml'))

    # Refresh the page every `refresh_interval` seconds.
    refresh_interval = config['config'][0]['refresh_interval'].to_s

    # For each Jenkins instance in "jobs", connect to the server,
    # and get the status of the jobs specified in the config.
    errors          = []
    failed_jobs     = []
    building_jobs   = []
    successful_jobs = []

    config['views'].select { |h| h[this_view] }[0].each do |_, servers|
      servers.each do |hash|
        hash.keys.each do |server|
          client = JenkinsApi::Client.new(:server_url => server)

          begin
            client.get_root  # Attempt a connection to `server`
          rescue SocketError
            errors << "Unable to connect to server: #{server}"
            next
          end

          hash[server][0]['jobs'].each do |job|
            job_details = client.job.list_details(job)
            case client.job.color_to_status(job_details['color'])
            when 'running'
              building_jobs << job_details
            when 'failure'
              failed_jobs << job_details
            when 'success'
              successful_jobs << job_details
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
      nirvana_img = "../img/img0#{wday}.png"
    end

    erb :view,
      :locals => {
      :refresh_interval => refresh_interval,
      :this_view        => this_view,
      :views            => get_views(),
      :nirvana          => nirvana,
      :nirvana_img      => nirvana_img,
      :errors           => errors,
      :failed_jobs      => failed_jobs,
      :building_jobs    => building_jobs,
      :successful_jobs  => successful_jobs,
    }
  end
end

