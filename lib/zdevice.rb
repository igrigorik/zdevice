require 'ffi-rzmq'

module ZMQ
  module Device

    class Builder
      def initialize(conf = {})
        @context = Context.new(conf.delete(:context))
        @devices = {}

        conf.each do |name, c|
          p [name, c]
          @devices[name] = Device.new(name, c)
        end
      end

      def method_missing(method, *args, &blk)
        if d = @devices[method]
          return d
        end

        super
      end
    end

    class Context
      attr_reader :iothreads, :verbose
      def initialize(conf = {})
        @iothreads = conf[:iothreads] || 1
        @verbose   = conf[:verbose]   || false

        @ctx = ZMQ::Context.new(@iothreads)
      end
    end

    class Device
      attr_reader :name, :type
      def initialize(name, conf = {})
        raise 'invalid name' if name == 'context'
        raise 'missing type' if !conf.key? :type

        @name = name
        @type = conf.delete(:type)
        # TODO: open sockets...
      end
    end

    class ZSocket
      attr_reader :name, :type
      def initialize(name, conf = {})
        raise 'invalid name' if name == 'type'
        raise 'missing type' if !conf.key? :type

        # [:type, :bind, :connect, :option].each do |var|
          # raise "missing #{var}" if !conf.key? var
        # end

        @name = name
        @type = conf.delete(:type)

      end
    end

  end

end
