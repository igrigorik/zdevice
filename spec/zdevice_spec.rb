require 'lib/zdevice'

include ZMQ::Device

describe ZMQ::Device do

  let(:ctx) { ZMQ::Context.new }

  context Builder do
    it "should symbolize configuration keys" do
      b = Builder.new(
        'context' => { 'iothreads' => 5 },
        'main' => {
          'type' => :queue,
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
