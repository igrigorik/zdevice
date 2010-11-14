require 'lib/zdevice'

include ZMQ::Device
describe ZMQ::Device do

  context Builder do
    it "should assemble a ZMQ Device" do
      b = Builder.new(
        context: { iothreads: 5},
        main: {
          type: :queue,
          frontend: { type: :SUB, option: { hwm: 1, swap: 25}, bind: "tcp://127.0.0.1:5555" },
          backend: { bind: "tcp://eth0:5556" }
        }
      )

      b.main.class.should == Device
      b.main.type.should == :queue

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
      lambda { Device.new('context', type: :a) }.should raise_error
      d = Device.new('valid', type: :a)
      d.name.should == 'valid'
    end
  end

  context ZSocket do
    it "should have any name except 'type'" do
      lambda { ZSocket.new('type') }.should raise_error('invalid name')

      s = ZSocket.new('valid', type: :queue)
      s.name.should == 'valid'
    end

    it "should have a type" do
      s = ZSocket.new('valid', type: :queue)
      s.type.should == :queue
    end

    # it "should have zero or more endpoints to bind the socket to"
    # it "should have zero or more endpoints to connect the socket to"
    # it "should have socket options"
  end

end
