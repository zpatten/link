# frozen_string_literal: true

require 'concurrent-edge'

module Factorio
  class Mods

################################################################################

    def initialize
      @mod_list = (JSON.parse(IO.read(filename).strip) rescue Hash.new)
      @mod_entries = @mod_list['mods']

      LinkLogger.info(:mods) { "Loaded Mod List: #{filename.ai}" }
      LinkLogger.debug(:mods) { @mod_list.ai }
    end

################################################################################

    def filename
      File.expand_path(File.join(LINK_ROOT, 'mods', 'mod-list.json'))
    end

    def save
      @mod_entries.keep_if do |mod_entry|
        if mod_entry['name'] == 'base'
          true
        elsif !(file = files.find { |f| f[:file].include?(mod_entry['name']) }).nil?
          filename = File.expand_path(File.join(Servers.factorio_mods, file[:file]))
          result = File.exist?(filename)
        else
          false
        end
      end
      @mod_entries.sort_by! { |mod_entry| mod_entry['name'].downcase }

      IO.write(filename, JSON.pretty_generate(@mod_list)+"\n")

      LinkLogger.info(:mods) { "Saved Mod List: #{filename.ai}" }

      true
    end

    def mod_entry(key)
      if (mod_entry = @mod_entries.find { |m| m['name'] == key }).nil?
        mod_entry = {
          'name' => key,
          'enabled' => false
        }
        @mod_entries << mod_entry
      end

      LinkLogger.debug(:mods) { "mod_entry(#{key.ai}): #{mod_entry.ai}" }

      mod_entry
    end

################################################################################

    def enabled?(key)
      mod_entry(key)['enabled']
    end

################################################################################

    def enable(key)
      mod_entry(key)['enabled'] = true
    end

    def disable(key)
      mod_entry(key)['enabled'] = false
    end

################################################################################

    def names
      (%w( base ) + files.collect { |m| m[:name] }.uniq).sort_by { |m| m.downcase }
    end

    def files
      filepath  = File.expand_path(File.join(Servers.factorio_mods, '*.zip'))
      mod_files = Dir.glob(filepath, File::FNM_CASEFOLD)
      mod_files = mod_files.collect do |mod_file|
        {
          name: File.basename(mod_file).split('_')[0..-2].join('_'),
          file: File.basename(mod_file),
          size: File.size(mod_file),
          time: File.mtime(mod_file)
        }
      end.sort_by { |mod_file| mod_file[:file] }

      mod_files.each do |mod_file|
        mod_entry(mod_file[:name])
      end

      mod_files
    end

################################################################################

    def search(name:, page: nil)
      uri = mod_portal_api_uri
      options = {
        query: {
          hide_deprecated: false,
          namelist: name.strip,
          sort_order: 'title',
          sort: 'asc',
          page: page
        }.delete_if { |k,v| v.nil? || v == '' }
      }
      LinkLogger.debug(:mods) { "uri=#{uri.ai}, options=#{options.ai}" }
      LinkLogger.info(:mods) { "Searching Factorio Mod Portal: name=#{name.ai}, page=#{page.ai}" }

      response = HTTParty.get(uri, options)
      response.parsed_response
    end

    def download(file_name:, download_url:, released_at:)
      options = {
        stream_body: true,
        follow_redirects: true
      }
      uri      = mod_portal_download_uri(download_url)
      filename = File.expand_path(File.join(Servers.factorio_mods, file_name))

      LinkLogger.debug(:mods) { "uri=#{uri.ai}, options=#{options.ai}" }
      LinkLogger.info(:mods) { "Downloading Mod #{filename.ai}" }

      File.open(filename, 'wb') do |file|
        HTTParty.get(uri, stream_body: true, follow_redirects: true, verify: false) do |fragment|
          file.write(fragment) if fragment.code == 200
        end
      end
      timestamp = DateTime.parse(released_at)
      File.utime(timestamp, timestamp, filename)

      LinkLogger.info(:mods) { "Downloaded Mod #{filename.ai} (#{countsize(File.size(filename)).ai})" }

      filename
    end

    def delete(filename)
      filename = File.expand_path(File.join(Servers.factorio_mods, filename))

      if File.exist?(filename)
        filesize = File.size(filename)

        LinkLogger.warn(:mods) { "Deleting Mod #{filename.ai} (#{countsize(filesize).ai})" }
        FileUtils.rm_f(filename)
        LinkLogger.warn(:mods) { "Deleted Mod #{filename.ai} (#{countsize(filesize).ai})" }

        true
      else
        false
      end
    end

################################################################################

    def mod_portal_api_uri
      URI::HTTPS.build(host: Config.factorio_mod_host, path: '/api/mods')
    end

    def mod_portal_download_uri(download_url)
      query = Array.new
      query << "username=#{Factorio::Credentials.username}"
      query << "token=#{Factorio::Credentials.token}"
      query = query.join('&')

      URI::HTTPS.build(host: Config.factorio_mod_host, path: download_url, query: URI.escape(query))
    end

    def mod_portal_uri(name)
      URI::HTTPS.build(host: Config.factorio_mod_host, path: "/mod/#{URI.escape(name)}")
    end

################################################################################

    module ClassMethods
      @@mods ||= Factorio::Mods.new

      def method_missing(method_name, *args, **options, &block)
        if options.count == 0
          @@mods.send(method_name, *args, &block)
        else
          @@mods.send(method_name, *args, **options, &block)
        end
      end
    end

    extend ClassMethods

################################################################################

  end
end
