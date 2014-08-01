require 'waylon/errors'

class Waylon
  class RootConfig

    require 'waylon/view'
    require 'waylon/app_config'

    attr_accessor :views
    attr_accessor :app_config

    def self.from_hash(hash)
      new.tap do |x|
        x.views  = hash['views'].map { |kvp| Waylon::View.from_hash(*kvp) }
        x.app_config = Waylon::AppConfig.from_hash(hash['config'])
      end
    end

    def view(name)
      @views.find { |view| view.name == name }.tap do |x|
        raise Waylon::Errors::NotFound, "Cannot find view named #{name}" if x.nil?
      end
    end
  end
end
