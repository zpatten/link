class MethodProxy

  RECV_MAX_LEN = (64 * 1024)

  attr_reader :thread

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
      Timeout::timeout(TIMEOUT_METHOD_PROXY) do
        result = block.call
      end
    rescue Exception => e
      @block.call(e) unless @block.nil?
      $logger.fatal(:mproxy) { "Exception: #{e.message}" }
    end
    result
  end

  def event_loop
    loop do
      data = socket.recv(RECV_MAX_LEN)
      data = Marshal.load(data)
      id = data[:id]
      $logger.debug(:mproxy) { "[#{@name}] #{data.ai}" }
      case data[:type]
      when :request
        args = data[:args]
        tag = args.first.downcase #map(&:to_s).join('-')
        ThreadPool.thread("#{@name}-method-call-#{tag}") do
          result = call_method(*args)
          send_response(id, result)
        end
      when :response
        unless @responses[id].nil?
          @responses[id].fulfill(data[:result])
          $logger.debug(:mproxy) { "[#{@name}] Fulfilled Response (#{id})" }
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
      expires_at: Time.now.to_f + TIMEOUT_RESPONSE
    }
    data = Marshal.dump(data)
    socket.send(data, 0)
  end

  def send_request(*args)
    id = @id.increment
    @responses[id] = Concurrent::Promises.resolvable_future
    data = {
      type: :request,
      id: id,
      args: args
    }
    data = Marshal.dump(data)
    socket.send(data, 0)
    id
  end

  def recv_response(id)
    # resolve_on_timeout = [false, nil, Timeout::Error]
    # value!(FUTURE_TIMEOUT, nil, resolve_on_timeout)
    result = @responses[id].value
    $logger.debug(:mproxy) { "[#{@name}] Resolved Response(#{id})" }

    result

  ensure
    @responses.delete(id)
  end

  def thread
    (parent? ? @parent_thread : @child_thread)
  end

  def start(&block)
    @block = block
    (parent? ? @parent_socket : @child_socket).close
    tag = parent? ? 'parent' : 'child'

    event_thread = ThreadPool.thread("#{@name}-method-proxy-#{tag}") do
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

  def call_method(*args)
    if Object.constants.include?(args.first)
      Object.const_get(args.first).send(*args[1..-1])
    else
      @object.send(*args)
    end
  end

  def method_missing(*args)
    # if parent?
      exception_wrapper do
        id = send_request(*args)
        $logger.debug(:mproxy) { "[#{@name}] method_missing(#{id}): #{args.ai}" }
        recv_response(id)
      end
    # else
    #   id = send_request(*args)
    #   $logger.debug(:mproxy) { "[#{@name}] method_missing(#{id}): #{args.ai}" }
    #   recv_response(id)
    # end
  end

end
