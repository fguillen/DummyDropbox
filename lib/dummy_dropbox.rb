begin
  require 'dropbox'
rescue LoadError
  require 'rubygems'
  require 'dropbox'
end
require 'ostruct'

module DummyDropbox
  @@root_path = File.expand_path( "#{File.dirname(__FILE__)}/../test/fixtures/dropbox" )
  
  def self.root_path=(path)
    @@root_path = path
  end
  
  def self.root_path
    @@root_path
  end
end

module Dropbox
  class Session
    def initialize(oauth_key, oauth_secret, options={})
      @ssl = false
      @consumer = OpenStruct.new( :key => "dummy key consumer" )
      @request_token = "dummy request token"
    end
    
    def authorize_url(*args)
      return 'https://www.dropbox.com/0/oauth/authorize'
    end
    
    def authorize(options={})
      return true
    end
    
    def authorized?
      return true
    end
    
    def serialize
      return 'dummy serial'
    end
    
    def self.deserialize(data)
      return Dropbox::Session.new( 'dummy_key', 'dummy_secret' )
    end
    
    #################
    # API methods
    #################
    
    def download(path, options={})
      raise UnsuccessfulResponseError.new(path, Net::HTTPNotFound) unless File.exists?("#{Dropbox.files_root_path}/#{path}")
      File.read( "#{Dropbox.files_root_path}/#{path}" )
    end

    def delete(path, options={})
      FileUtils.rm_rf( "#{Dropbox.files_root_path}/#{path}" )
      
      return true
    end

    def create_folder(path, options={})
      folder_path = "#{Dropbox.files_root_path}/#{path}"
      raise FileExistsError.new(path) if File.directory?(folder_path)
      FileUtils.mkdir(folder_path)
      return self.metadata( path )
    end

    def rename(path, new_name, options={})
      path = path.sub(/\/$/, '')
      destination = path.split('/')
      destination[destination.size - 1] = new_name
      destination = destination.join('/')
      move path, destination, options
    end

    def move(source, target, options={})
      FileUtils.mv("#{Dropbox.files_root_path}/#{source}", "#{Dropbox.files_root_path}/#{target}")
      return true
    end
    
    # TODO: the original gem method allow a lot of types for 'local_path' parameter
    # this dummy version only allows a file_path
    def upload(local_file_path, remote_folder_path, options={})
      if(local_file_path.kind_of? StringIO)
        local_file = Tempfile.new("dummy_dropbox_#{Time.now.to_i}") do |f|
          f.write local_file_path.to_s
        end
        local_file_path = local_file.path
        FileUtils.cp( local_file_path, "#{Dropbox.files_root_path}/#{remote_folder_path}/#{options[:as]}" )
        outfile = "#{remote_folder_path}/#{options[:as]}"
      else
        FileUtils.cp( local_file_path, "#{Dropbox.files_root_path}/#{remote_folder_path}/" )
        outfile = "#{remote_folder_path}/#{File.basename(local_file_path)}"
      end
      
      return self.metadata( outfile )
    end
    
    def metadata(path, options={})
      is_dir = File.directory?( "#{Dropbox.files_root_path}/#{path}" )
      mime_type = is_dir ? "" : ',"mime_type": "image/jpeg"'

      response = <<-RESPONSE
        {
          "thumb_exists": false,
          "bytes": #{File.size( "#{Dropbox.files_root_path}/#{path}" )},
          "modified": "Tue, 04 Nov 2008 02:52:28 +0000",
          "path": "#{path}",
          "is_dir": #{is_dir},
          "size": "566.0KB",
          "root": "dropbox",
          "icon": "page_white_acrobat",
          "hash": "theHash",
          "revision": #{is_dir ? 32 : 79}
          #{mime_type}
        }
      RESPONSE

      return parse_metadata(JSON.parse(response).symbolize_keys_recursively).to_struct_recursively
    end
    
    def list(path, options={})
      result = []
      
      Dir["#{Dropbox.files_root_path}/#{path}/**"].each do |element_path|
        element_path.gsub!( "#{Dropbox.files_root_path}/", '' ).gsub!(/^\/+/,'/')

        is_dir = File.directory?( "#{Dropbox.files_root_path}/#{element_path}" )

        element = 
          OpenStruct.new(
            :icon => 'folder',
            :'directory?' => File.directory?( "#{Dropbox.files_root_path}/#{element_path}" ),
            :path => element_path,
            :thumb_exists => false,
            :modified => Time.parse( '2010-01-01 10:10:10' ),
            :revision => 1,
            :bytes => (is_dir ? 0 : File.size( "#{Dropbox.files_root_path}/#{element_path}" )),
            :is_dir => is_dir,
            :size => '0 bytes'
          )
        
        result << element
      end
      
      return result
    end
    
    def account
      response = <<-RESPONSE
      {
          "country": "",
          "display_name": "John Q. User",
          "email": "john@user.com",
          "quota_info": {
              "shared": 37378890,
              "quota": 62277025792,
              "normal": 263758550
          },
          "uid": "174"
      }
      RESPONSE
      
      return JSON.parse(response).symbolize_keys_recursively.to_struct_recursively
    end
  end

  def self.files_root_path
    return DummyDropbox::root_path
  end

  class APIError < StandardError
    # The request URL.
    attr_reader :request
    # The Net::HTTPResponse returned by the server.
    attr_reader :response

    def initialize(request, response) # :nodoc:
      @request = request
      @response = response
    end

    def to_s # :nodoc:
      "API error: #{request}"
    end
  end

  class UnsuccessfulResponseError < APIError
    def to_s
      "HTTP status #{@response.class.to_s} received: #{request}"
    end
  end

  class FileExistsError < FileError; end
  class FileNotFoundError < FileError; end

end
