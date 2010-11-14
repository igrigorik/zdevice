require 'lib/zdevice'

include ZMQ::Device
describe ZMQ::Device do

  let(:ctx) { ZMQ::Context.new }

  context Builder do
    it "should assemble a one-time relay ZMQ Device" do
      b = Builder.new(
        context: { iothreads: 5},
        main: {
          type: :queue,
          frontend: { type: :SUB, option: { hwm: 1, swap: 25}, connect: ["tcp://127.0.0.1:5555"] },
          backend: { type: :PUB, bind: ["tcp://127.0.0.1:5556"] }
        }
      )

      b.main.class.should == Device
      b.main.type.should == :queue

      # Create producer socket
      sctx = ZMQ::Context.new
      pub = sctx.socket(ZMQ::PUB)
      pub.bind("tcp://127.0.0.1:5555")

      # Start queue device
      Thread.new do
        b.main.start do
          msg = ZMQ::Message.new
          p 'broker fronted listening'
          frontend.recv msg
          p 'broker got msg'
          backend.send msg
        end
      end

      # Start producer
      Thread.new do
        loop do
          pub.send ZMQ::Message.new("queue test")
          sleep(1)
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
  end

  context Context do
    it "should accept optional iothread count" do
      c = Context.new(iothreads: 5)
      c.iothreads.should == 5
    end

    it "should accept optional verbose flag" do
      c = Context.new(verbose: true)
      c.verbose.should be_true
    end
  end

  context Device do
    it "should validate type" do
      lambda { Device.new('context') }.should raise_error
    end

    it "should validate name" do
      lambda { Device.new('context', ctx, type: :a) }.should raise_error
      d = Device.new('valid', nil, type: :a)
      d.name.should == 'valid'
    end
  end

  context ZSocket do
    it "should have any name except 'type'" do
      lambda { ZSocket.new('type') }.should raise_error('invalid name')

      s = ZSocket.new('valid', ctx, type: :queue)
      s.name.should == 'valid'
      s.close
    end

    it "should have a type" do
      s = ZSocket.new('valid', ctx, type: :queue)
      s.type.should >= 0
      s.close
    end

    it "should setup subscription filters"
  end

end
