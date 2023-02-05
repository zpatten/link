# frozen_string_literal: true

class Servers
  module Saves

################################################################################

    def save_path
      File.expand_path(File.join(LINK_ROOT, 'saves'))
    end

    def saves
      begin
        FileUtils.mkdir_p(save_path)
      rescue Errno::ENOENT
      end

      save_files = Dir.glob(File.join(save_path, '*.zip'), File::FNM_CASEFOLD)
      save_files.collect do |save_file|
        {
          file: File.basename(save_file),
          size: File.size(save_file),
          time: File.mtime(save_file)
        }
      end.sort_by { |save_file| save_file[:file] }
    end

    def time_index
      %i( year month day hour min )
    end

    def build_date_hash(timestamp, h, v, modifier=0)
      return false if modifier >= time_index.size

      x = timestamp.send(time_index[modifier])
      h[x] ||= Hash.new
      h[x] = v if !build_date_hash(timestamp, h[x], v, modifier + 1)

      true
    end

    def save_files_to_trim(save_files)
      save_files.sort! { |a, b| a <=> b }
      save_files[0..-2]
    end

    def trim_saves
      LinkLogger.debug(:servers) { "Trimming save files..." }
      save_file_hash = Hash.new
      save_files = Dir.glob(File.join(save_path, "*.zip"), File::FNM_CASEFOLD)
      save_files.each do |save_file|
        basename = File.basename(save_file, '.*')
        separator = basename.rindex('-')
        next if separator.nil?

        server_name = basename[0, separator]
        timestamp = basename[separator+1..-1]
        next if server_name.nil? || timestamp.nil?

        save_file_hash[server_name] ||= Array.new
        save_file_hash[server_name] << [timestamp, save_file]
      end

      now = Time.now
      save_file_hash.each do |server_name, save_files|
        next if save_files.size <= 1
        save_files.sort! { |(atime,afile),(btime,bfile)| atime <=> btime }
        h = Hash.new
        save_files.each do |save_file|
          build_date_hash(Time.at(save_file[0].to_i), h, save_file[1])
        end
        delete_save_files = Array.new
        h.each_pair do |year, months|
          months.each_pair do |month, days|
            if now.month != month
              file_pairs = days.values.map(&:values).flatten.map(&:values).flatten
              delete_save_files << save_files_to_trim(file_pairs)
            end
            days.each_pair do |day, hours|
              if now.day != day
                file_pairs = hours.values.map(&:values).flatten
                delete_save_files << save_files_to_trim(file_pairs)
              end
              hours.each_pair do |hour, minutes|
                if now.day == day && now.hour != hour
                  delete_save_files << save_files_to_trim(minutes.values.flatten)
                end
              end
            end
          end
        end

        next if delete_save_files.nil? || delete_save_files.empty?

        delete_save_files.flatten!.uniq!
        delete_save_files.each do |delete_save_file|
          LinkLogger.warn(:servers) { "Trimming save file #{File.basename(delete_save_file).ai}" }
        end
        FileUtils.rm_f(delete_save_files)
      end

      true
    end

################################################################################

  end
end
