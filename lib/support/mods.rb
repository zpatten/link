# frozen_string_literal: true

require 'concurrent-edge'

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
    LinkLogger.info(:mods) { "mod_entry(#{key.ai}): #{mod_entry.ai}" }
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
    mod_files = Dir.glob(File.join(Servers.factorio_mods, '*.zip'), File::FNM_CASEFOLD)
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

  def search(name)
    options = {
      query: {
        hide_deprecated: false,
        namelist: params[:name].strip,
        sort_order: 'title',
        sort: 'asc',
        page: params[:page]
      }.delete_if { |k,v| v.nil? || v == '' }
    }
    LinkLogger.info(:mods) { "options=#{options.ai}" }
    response         = HTTParty.get("#{Config.factorio_mod_url}/api/mods", options)
    @name            = params[:name]
    @parsed_response = response.parsed_response
  end

################################################################################

  module ClassMethods
    @@mods ||= Mods.new

    def method_missing(method_name, *args, **options, &block)
      @@mods.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
