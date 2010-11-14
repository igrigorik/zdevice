require 'ffi-rzmq'

module ZMQ
  module Device

    class Builder
      def initialize(conf = {})
        conf = symbolize_keys(conf)
        @context = Context.new(conf.delete(:context))

        @devices = {}
        conf.each do |name, c|
          @devices[name] = Device.new(name, @context.ctx, c)
        end
      end

      def symbolize_keys(conf)
        recursive = Proc.new do |h, sh|
          h.each do |k,v|
            sh[k.to_sym] = v.is_a?(Hash) ? recursive.call(v, {}) : v
          end
          sh
        end

        recursive.call(conf, {})
      end

      def close
        @devices.values.map { |d| d.close }
      end

      def method_missing(method, *args, &blk)
        if d = @devices[method]
          return d
        end
        super
      end
    end

    class Context
      attr_reader :iothreads, :verbose, :ctx
      def initialize(conf = {})
        @iothreads = conf[:iothreads] || 1
        @verbose   = conf[:verbose]   || false

        @ctx = ZMQ::Context.new(@iothreads)
      end
    end

    class Device
      attr_reader :name, :type
      def initialize(name, ctx, conf = {}, &blk)
        raise 'invalid name' if name == 'context'
        raise 'missing type' if !conf.key? :type

        @name = name
        @type = conf.delete(:type)

        @sockets = {}
        conf.each do |name, c|
          @sockets[name] = ZSocket.new(name, ctx, c)
        end
      end

      def start(&blk)
        instance_eval &blk
      end

      def close
        @sockets.values.map {|s| s.close }
      end

      def method_missing(method, *args, &blk)
        if s = @sockets[method]
          return s.socket
        end
        super
      end
    end

    class ZSocket
      attr_reader :name, :type, :socket
      def initialize(name, ctx = nil, conf = {})
        raise 'invalid name' if name == 'type'
        raise 'missing type' if !conf.key? :type

        @name = name
        @type = case conf.delete(:type).downcase
          when :pub then ZMQ::PUB
          when :sub then ZMQ::SUB
          else 1
        end

        @socket = ctx.socket @type
        (conf[:bind]    || []).each { |addr| @socket.bind addr }
        (conf[:connect] || []).each { |addr| @socket.connect(addr); @socket.setsockopt(ZMQ::SUBSCRIBE, '') }
      end

      def close
        @socket.close
      end
    end

  end

end
