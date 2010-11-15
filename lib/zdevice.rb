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
          (class << self; self; end).class_eval do
            define_method "#{name}" do
              @devices[name]
            end
          end
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
          (class << self; self; end).class_eval do
            define_method "#{name}" do
              @sockets[name].socket
            end
          end
        end
      end

      def start(&blk)
        instance_eval &blk
      end

      def close
        @sockets.values.map {|s| s.close }
      end
    end

    class ZSocket
      attr_reader :name, :type, :socket
      def initialize(name, ctx = nil, conf = {})
        raise 'invalid name' if name == 'type'
        raise 'missing type' if !conf.key? :type

        @name = name
        conf[:option] ||= {}
        @type = case conf.delete(:type).downcase
          when :pub then ZMQ::PUB
          when :sub then ZMQ::SUB
          else 1
        end

        # if no filter is specified, then accept all messages by default
        if @type == ZMQ::SUB
          conf[:option][:subscribe] = '' if !conf[:option][:subscribe]
        end

        @socket = ctx.socket @type
        (conf[:bind]    || []).each { |addr| @socket.bind addr }
        (conf[:connect] || []).each { |addr| @socket.connect(addr) }

        conf[:option].each do |k, v|
          flag = case k
          when :subscribe then ZMQ::SUBSCRIBE
          when :hwm       then ZMQ::HWM
          when :swap      then ZMQ::SWAP
          end

          [v].flatten.map {|val| @socket.setsockopt(flag, val) }
        end
      end

      def close
        @socket.close
      end
    end

  end

end