require 'sinatra'
require 'cgi'
require 'date'
require 'jenkins_api_client'
require 'yaml'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')


class Waylon < Sinatra::Application
  require 'waylon/root_config'

  helpers do
    def h(text)
      CGI::escape(text)
    end

    # get_views() does just that, gets a list of views from
    # the config file and returns an array of strings.
    def get_views()
      gen_config.views.map(&:name)
    end

    def gen_config
      root = File.dirname(__FILE__)
      config = YAML.load_file(File.join(root, 'config/waylon.yml'))
      Waylon::RootConfig.from_hash(config)
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
    config = gen_config
    @this_view = CGI.unescape(params[:name])
    @refresh_interval = config.app_config.refresh_interval

    view_config = config.views.find { |view| view.name == @this_view }

    if view_config.nil?
      @errors = [ "Couldn't find view #{@this_view}!"]
    end

    erb :base do
      erb :view
    end
  end

  # Individual views' data (`/view/foo/data`)
  # When navigating to 'view/foo/data', queries config/waylon.yml for that
  # view's config (servers to connect to, and jobs to display). Returns an
  # HTML table for the jQuery in '/view/:name' to load and display.
  get '/view/:name/data' do
    @this_view = CGI.unescape(params[:name])

    # For each Jenkins instance in a view, connect to the server, and get the
    # status of the jobs specified in the config. Append job details to each
    # applicable array: successful, failed, and building.
    @errors          = []
    @warnings        = []
    @failed_jobs     = []
    @failed_builds   = []
    @building_jobs   = []
    @job_progress    = []
    @successful_jobs = []

    view_config = gen_config.views.find { |view| view.name == @this_view }

    if view_config.nil?
      @errors << "Couldn't find view #{@this_view}!"
      halt 404
    end


    view_config.servers.each do |server|
      begin
        server.verify_client!
      rescue SocketError
        @errors << "Unable to connect to server: #{server}"
        next
      rescue Errno::ETIMEDOUT
        @errors << "Timed out while connecting to server: #{server}"
        next
      end

      server.jobs.each do |job|

        # jenkins_api_client won't throw an Unauthorized exception until
        # we really try doing something, like calling list_details()
        begin
          job.query!
          job_details = job.job_details
        rescue JenkinsApi::Exceptions::Unauthorized
          @errors << "Incorrect username or password for server: #{server.url}"
          break
        rescue JenkinsApi::Exceptions::NotFound
          @warnings << "Non-existent job \"#{job.name}\" on server #{server.url}"
          next
        end

        case job.status
        when 'running'
          @building_jobs << job_details

          @job_progress << {
            'job_name'     => job.name,
            'progress_pct' => job.progress_pct,
            'eta'          => job.eta
          }
        when 'failure'
          @failed_jobs << job_details

          @failed_builds << {
            'job_name'               => job.name,
            'build_number'           => job.last_build_num,
            'is_under_investigation' => job.under_investigation?
          }
        when 'success'
          @successful_jobs << job_details
        end
      end
    end

    erb :data
  end

  # Investigate a failed build
  #
  get '/view/:view/:server/:job/:build/investigate' do
    server   = CGI.unescape(params[:server])
    job      = CGI.unescape(params[:job])
    build    = CGI.unescape(params[:build])
    postdata = { 'description' => 'Under investigation' }
    prefix   = "/job/#{job}/#{build}"

    # We need to get the server URL from the configuration file, based on just
    # the hostname, to keep the server's full URL (and all its special chars)
    # out of the URI visible to the user. This whole thing is a hack and should
    # be improved someday.
    gen_config.views.each do |view|
      view.servers.each do |config_server|
        if config_server.url =~ /#{server}/
          config_server.client.api_post_request("#{prefix}/submitDescription", postdata)
          redirect "#{config_server.url}/#{prefix}/"
        end
      end
    end

    @errors = []
    @errors << "We couldn't find a server in our config for #{server}!"

    @this_view = 'index'

    erb :base do
      erb :index
    end
  end
end
