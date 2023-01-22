class MethodProxy

  RECV_MAX_LEN = (64 * 1024)

  def initialize(object, parent_pid)
    @object = object
    @name = object.name
    @child_socket, @parent_socket = UNIXSocket.pair(:DGRAM)

    @id = Concurrent::AtomicFixnum.new
    @responses = Concurrent::Hash.new

    @parent_pid = parent_pid
  end

  def parent?
    Process.pid == @parent_pid
  end

  def socket
    (parent? ? @child_socket : @parent_socket)
  end

  def exception_wrapper(&block)
    result = nil
    begin
      Timeout::timeout(METHOD_PROXY_TIMEOUT) do
        result = block.call
      end
    rescue Exception => e
      @block.call(e) unless @block.nil?
      $logger.fatal(:mproxy) { "[#{tag}] Exception: #{e.message}" }
    end
    result
  end

  def event_loop
    loop do
      data = socket.recv(RECV_MAX_LEN)
      data = Marshal.load(data)
      id = data[:id]
      $logger.debug(:mproxy) { "[#{tag}] #{data.ai}" }
      case data[:type]
      when :request
        args = data[:args]
        options = data[:options]
        t = [tag, 'call', args.first.downcase].join('-')
        ThreadPool.thread(t) do
          # exception_wrapper do
            result = call_method(*args, **options)
            send_response(id, result)
          # end
        end
      when :response
        unless @responses[id].nil?
          @responses[id].fulfill(data[:result])
          $logger.debug(:mproxy) { "[#{tag}] Fulfilled Response (#{id})" }
        end
      else
        raise "Invalid Type"
      end
    end
  end

  def send_response(id, result)
    data = {
      type: :response,
      id: id,
      result: result,
      expires_at: Time.now.to_f + RESPONSE_TIMEOUT
    }
    data = Marshal.dump(data)
    socket.send(data, 0)
  end

  def send_request(*args, **options)
    id = @id.increment
    @responses[id] = Concurrent::Promises.resolvable_future
    data = {
      type: :request,
      id: id,
      args: args,
      options: options
    }
    data = Marshal.dump(data)
    socket.send(data, 0)
    id
  end

  def recv_response(id)
    # resolve_on_timeout = [false, nil, Timeout::Error]
    # value!(FUTURE_TIMEOUT, nil, resolve_on_timeout)
    result = @responses[id].value
    $logger.debug(:mproxy) { "[#{tag}] Resolved Response(#{id})" }

    result

  ensure
    @responses.delete(id)
  end

  def thread
    (parent? ? @parent_thread : @child_thread)
  end

  def tag
    @tag ||= begin
      t = Array.new
      t << @name
      t << 'mproxy'
      t << (parent? ? 'parent' : 'child')
      t.flatten.compact.map(&:to_s).map(&:downcase).join('-')
    end
  end

  def start(&block)
    @block = block
    (parent? ? @parent_socket : @child_socket).close

    event_thread = ThreadPool.thread(tag) do
      event_loop
    end

    if parent?
      @parent_thread = event_thread
    else
      @child_thread = event_thread
    end

    event_thread
  end

  def stop
    thread.exit
    close
  end

  def close(socket=nil)
    if socket.nil?
      @child_socket.close unless @child_socket.closed?
      @parent_socket.close unless @parent_socket.closed?
    else
      socket.close unless socket.closed?
    end
  end

  def call_method(*args, **options)
    # puts args.ai
    # puts options.ai
    if Object.constants.include?(args.first)
      Object.const_get(args.first).send(*args[1..-1], **options)
    else
      @object.send(*args, **options)
    end
  end

  def method_missing(*args, **options)
    # if parent?
      exception_wrapper do
        id = send_request(*args, **options)
        $logger.debug(:mproxy) { "[#{tag}] method_missing(#{id}): #{args.ai} #{options.ai}" }
        recv_response(id)
      end
    # else
    #   id = send_request(*args)
    #   $logger.debug(:mproxy) { "[#{@name}] method_missing(#{id}): #{args.ai}" }
    #   recv_response(id)
    # end
  end

end
