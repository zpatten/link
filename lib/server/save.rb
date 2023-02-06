# frozen_string_literal: true

class Server
  module Save

################################################################################

    def save(timestamp: false)
      return false if container_dead? || unresponsive?
      if File.exist?(self.save_file)
        begin
          FileUtils.mkdir_p(Servers.save_path)
        rescue Errno::ENOENT
        end

        filename = if timestamp
          "#{@name}-#{Time.now.to_i}.zip"
        else
          "#{@name}.zip"
        end
        backup_save_file = File.join(Servers.save_path, filename)
        latest_save_file = self.latest_save_file
        FileUtils.cp_r(latest_save_file, backup_save_file)
        LinkLogger.info(log_tag(:save)) { "Backed up #{latest_save_file.ai} to #{backup_save_file.ai}" }
      end

      rcon_command %(/server-save)

      true
    end

################################################################################

  end
end
