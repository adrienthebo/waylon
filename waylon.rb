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
      Waylon::RootConfig.from_hash(load_config)
    end

    # load_config() opens config/waylon.yml, parses it, and returns
    def load_config()
      root = File.dirname(__FILE__)
      config = YAML.load_file(File.join(root, 'config/waylon.yml'))
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
      # This is wrapped inside a block to ensure that we display an error
      # if the user has an improperly-formatted YAML file. That is, they
      # have omitted 'username', 'password' or both. If that's the case,
      # a NoMethodError will be raised.
      begin
        username = server.username
        password = server.password

        if(!username.empty? and !password.empty?)
          client = JenkinsApi::Client.new(
            :server_url => server.url,
            :username   => username,
            :password   => password,
          )
        else
          @errors << "No credentials provided for server: #{server}"
          next
        end
      rescue NoMethodError
        @errors << "No credentials provided for server: #{server}"
        next
      end

      begin
        client.get_root  # Attempt a connection to `server`
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
          job_details = client.job.list_details(job)
        rescue JenkinsApi::Exceptions::Unauthorized
          @errors << "Incorrect username or password for server: #{server}"
          break
        rescue JenkinsApi::Exceptions::NotFound
          @warnings << "Non-existent job \"#{job}\" on server #{server}"
          next
        end

        case client.job.color_to_status(job_details['color'])
        when 'running'
          @building_jobs << job_details

          # The values we need for getting progress and estimating time
          # remaining aren't available in jenkins_api_client's methods.
          # Luckily, api_get_request() is public and we can re-use our
          # existing connection.
          est_duration = client.api_get_request("/job/#{job}/lastBuild", nil, "/api/json?depth=2&tree=estimatedDuration")['estimatedDuration']

          progress_pct = String.new
          begin
            client.api_get_request("/job/#{job}/lastBuild", nil, "/api/json?depth=3")['runs'].each do |run|
              progress_pct = run['executor']['progress']
            end
            # A build's 'duration' in the Jenkins API is only available
            # after it has completed. Using estimatedDuration and the
            # executor progress (in percentage), we can calculate the ETA.
            # Note that estimatedDuration is returned in ms and here we
            # convert it to seconds.
            eta = (est_duration - (est_duration * (progress_pct / 100.0))) / 1000
          rescue NoMethodError
            # the build is stuck, or something horrible happened
            progress_pct = -1
            eta          = -1
          ensure
            @job_progress << {
              'job_name'     => job,
              'progress_pct' => progress_pct,
              'eta'          => eta
            }
            next
          end
        when 'failure'
          @failed_jobs << job_details

          # We already know the job is in 'failed' state. Using the build
          # description (or lack thereof), build an array of hashes to
          # determine if the failed job is already under investigation.
          last_build_num = job_details['lastBuild']['number']
          last_build_descr = client.job.get_build_details(job, last_build_num)['description']

          if(last_build_descr =~ /under investigation/i)
            is_under_investigation = true
          else
            is_under_investigation = false
          end

          @failed_builds << {
            'job_name'               => job,
            'build_number'           => last_build_num,
            'is_under_investigation' => is_under_investigation,
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
    view     = CGI.unescape(params[:view])
    server   = CGI.unescape(params[:server])
    job      = CGI.unescape(params[:job])
    build    = CGI.unescape(params[:build])
    postdata = { 'description' => 'Under investigation' }
    prefix   = "/job/#{job}/#{build}"

    # We need to get the server URL from the configuration file, based on just
    # the hostname, to keep the server's full URL (and all its special chars)
    # out of the URI visible to the user. This whole thing is a hack and should
    # be improved someday.
    config = load_config()
    config['views'].select { |h| h[view] }[0].values.flatten.each do |hash|
      hash.keys.each do |server_url|
        if(server_url =~ /#{server}/)
            username = hash[server_url].select { |h| h['username'] }[0]['username']
            password = hash[server_url].select { |h| h['password'] }[0]['password']

            if(!username.empty? and !password.empty?)
              client = JenkinsApi::Client.new(
                :server_url => server_url,
                :username   => username,
                :password   => password,
              )
            end
            client.api_post_request("#{prefix}/submitDescription", postdata)
            redirect "#{server_url}/#{prefix}/"
        end
      end
    end
  end
end
