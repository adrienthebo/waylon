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
      config = load_config()
      views = []
      config['views'].each do |view|
        views += view.keys
      end
      return views
    end

    # load_config() opens waylon_config.yml, parses it, and returns
    def load_config()
      root = File.dirname(__FILE__)
      config = YAML.load_file(File.join(root, 'waylon_config.yml'))
      return config
    end

    # weather() returns an img src, alt, and title, based on build stability
    def weather(score)
      case score.to_i
      when 100
        {
          'src' => '/img/sun.png',
          'alt' => '[sun]',
          'title' => 'No recent builds failed'
        }
      when 80
        {
          'src' => '/img/cloud.png',
          'alt' => '[cloud]',
          'title' => '1 of the last 5 builds failed'
        }
      else
        {
          'src' => '/img/umbrella.png',
          'alt' => '[umbrella]',
          'title' => '2 or more of the last 5 builds failed'
        }
      end
    end
  end

  # Landing page (`/`)
  # Print a list of views available on this Waylon instance.
  get '/' do
    @this_view = 'index'

    erb :base do
      erb :index
    end
  end

  # Individual views (`/view/foo`)
  # These are the pages the user actually interacts with. Code here and
  # in the ERB templates for `view/foo` should be _just enough_ to refresh
  # the contents of <div class="waylon container"> with the latest data.
  get '/view/:name' do
    @this_view = Rack::Utils.unescape(params[:name])
    config = load_config()

    # Refresh the page every `refresh_interval` seconds.
    @refresh_interval = config['config'][0]['refresh_interval'].to_i

    erb :base do
      erb :view
    end
  end

  # Individual views' data (`/view/foo/data`)
  # When navigating to 'view/foo', queries waylon_config.yml for that view's
  # config (servers to connect to, and jobs to display). Returns HTML for the
  # jQuery in '/view/:name' to work with.
  get '/view/:name/data' do
    @this_view = Rack::Utils.unescape(params[:name])
    config = load_config()

    # For each Jenkins instance in a view, connect to the server, and get the
    # status of the jobs specified in the config. Append job details to each
    # applicable array: successful, failed, and building.
    @errors          = []
    @failed_jobs     = []
    @failed_builds   = []
    @building_jobs   = []
    @successful_jobs = []

    config['views'].select { |h| h[@this_view] }[0].each do |_, servers|
      servers.each do |hash|
        hash.keys.each do |server|
          client = JenkinsApi::Client.new(:server_url => server)

          begin
            client.get_root  # Attempt a connection to `server`
          rescue SocketError
            @errors << "Unable to connect to server: #{server}"
            next
          rescue Errno::ETIMEDOUT
            @errors << "Timed out while connecting to server: #{server}"
            next
          end

          hash[server][0]['jobs'].each do |job|
            job_details = client.job.list_details(job)
            case client.job.color_to_status(job_details['color'])
            when 'running'
              @building_jobs << job_details
            when 'failure'
              @failed_jobs << job_details

              # We already know the job is in 'failed' state. Using the build
              # description (or lack thereof), build an array of hashes to
              # determine if the failed job is already under investigation.
              last_build_num = job_details['lastBuild']['number']
              if(client.job.get_build_details(job, last_build_num)['description'] =~ /under investigation/i)
                is_under_investigation = true
              else
                is_under_investigation = false
              end

              @failed_builds << {
                'job_name'               => job_details['name'],
                'is_under_investigation' => is_under_investigation,
              }
            when 'success'
              @successful_jobs << job_details
            end
          end
        end
      end
    end

    erb :data
  end
end

