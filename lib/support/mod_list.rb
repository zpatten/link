# frozen_string_literal: true

require 'concurrent-edge'

class ModList

################################################################################

  def initialize
    @mod_list = (JSON.parse(IO.read(filename).strip) rescue Hash.new)

    LinkLogger.info(:mod_list) { "Loaded Mod List: #{filename.ai}" }
    LinkLogger.debug(:mod_list) { @mod_list.ai }
  end

################################################################################

  def filename
    File.expand_path(File.join(LINK_ROOT, 'mods', 'mod-list.json'))
  end

  def save
    IO.write(filename, "\n"+JSON.pretty_generate(to_h.sort.to_h)+"\n")
    LinkLogger.info(:mod_list) { "Saved Mod List: #{filename.ai}" }

    true
  end

  def to_h
    mod_list = Hash.new
    @mod_list.each do |key, mod|
      mod_list[key] = mod
    end
    mod_list
  end

################################################################################

  def enabled?(key)
    (@mod_list['mods'].find { |m| m['name'] == key }['enabled'] rescue false)
  end

################################################################################

  def enable(key)
    @mod_list['mods'].find { |m| m['name'] == key }['enabled'] = true
  end

  def disable(key)
    @mod_list['mods'].find { |m| m['name'] == key }['enabled'] = false
  end

################################################################################

  def names
    (%w( base ) + files.collect { |m| m[:name] }.uniq).sort_by { |m| m.downcase }
  end

  def files
    mod_files = Dir.glob(File.join(Servers.factorio_mods, '*.zip'), File::FNM_CASEFOLD)
    mod_files.collect do |mod_file|
      {
        name: File.basename(mod_file).split('_')[0..-2].join('_'),
        file: File.basename(mod_file),
        size: File.size(mod_file),
        time: File.mtime(mod_file)
      }
    end.sort_by { |mod_file| mod_file[:file] }
  end

################################################################################

  module ClassMethods
    @@mod_list ||= ModList.new

    def method_missing(method_name, *args, **options, &block)
      @@mod_list.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
