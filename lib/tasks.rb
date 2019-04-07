# Tasks
################################################################################
schedule_task(:statistics) do
  Storage.delta
end

schedule_task(:servers) do
  $logger.info { ("-" * 80) }

  Servers.all.each do |server|
    a = server.authenticated? ? "authenticated" : "UNAUTHENTICATED"
    c = server.connected? ? "connected" : "DISCONNECTED"
    $logger.info { "[#{server.id}] #{server.host_tag} - #{a} #{c}" }
  end

  $logger.info { ("-" * 80) }

  ThreadPool.log
end

# schedule_task(:display) do
#   ThreadPool.display
# end
