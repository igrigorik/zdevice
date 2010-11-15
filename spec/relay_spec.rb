require 'lib/zdevice'

include ZMQ::Device

describe "relay device" do

  it "should assemble a one-time relay ZMQ Device" do
    b = Builder.new(
      context: { iothreads: 5 },
      main: {
        type: :queue,

        frontend: {
          type: :SUB,
          option: { hwm: 1, swap: 25},
          connect: ["tcp://127.0.0.1:5555"]
        },

        backend: {
          type: :PUB,
        bind: ["tcp://127.0.0.1:5556"] }
      }
    )

    b.main.class.should == Device
    b.main.type.should == :queue

    # Create producer socket
    sctx = ZMQ::Context.new
    pub = sctx.socket(ZMQ::PUB)
    pub.bind("tcp://127.0.0.1:5555")

    # Start relay device
    Thread.new do
      b.main.start do
        msg = ZMQ::Message.new
        frontend.recv msg
        backend.send msg
      end
    end

    # Start producer
    Thread.new do
      loop do
        pub.send ZMQ::Message.new("queue test")
      end
    end

    # Consume re-routed message from producer
    sub = sctx.socket(ZMQ::SUB)
    sub.setsockopt(ZMQ::SUBSCRIBE, '')
    sub.connect("tcp://127.0.0.1:5556")

    rmsg = ZMQ::Message.new
    sub.recv rmsg

    rmsg.copy_out_string.should == "queue test"

    pub.close
    sub.close
    b.close
  end

  it "should have more Ruby friendly syntax" do
    pending "maybe"

    d = Device.new do
      context iothreads: 5, verbose: false

      device :queue do
        socket :frontend do
          type ZMQ::SUB
          option hwm: 1, swap: 25
          connect ['']
          bind ['']
        end
      end
    end

    d.queue.start do
    end
  end

end
