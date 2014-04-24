require 'spec_helper'

describe "Zuul::Context" do

  describe "parse" do
    it "should allow passing nil" do
      expect { Zuul::Context.parse(nil) }.to_not raise_exception
    end

    it "should allow passing a class" do
      expect { Zuul::Context.parse(Context) }.to_not raise_exception
    end

    it "should allow passing an instance" do
      context = Context.create(:name => "Test Context")
      expect { Zuul::Context.parse(context) }.to_not raise_exception
    end
    
    it "should allow passing another context" do
      expect { Zuul::Context.parse(Zuul::Context.new) }.to_not raise_exception
    end
    
    it "should allow passing a class_name and id" do
      expect { Zuul::Context.parse('Context', 1) }.to_not raise_exception
    end

    it "should return an Zuul::Context object with the context broken into it's two parts" do
      parsed = Zuul::Context.parse(nil)
      parsed.should be_an_instance_of(Zuul::Context)
    end
    
    it "should return a nil context context for nil" do
      parsed = Zuul::Context.parse(nil)
      parsed.class_name.should be_nil
      parsed.id.should be_nil
    end

    it "should return a context with class_name set to the class name for class context" do
      parsed = Zuul::Context.parse(Context)
      parsed.class_name.should == 'Context'
      parsed.id.should be_nil
    end
    
    it "should return a context with class_name and id set for an instance context" do
      context = Context.create(:name => "Test Context")
      parsed = Zuul::Context.parse(context)
      parsed.class_name.should == 'Context'
      parsed.id.should == context.id
    end
  end

  describe "#to_context" do
    it "should return nil for a nil context" do
      Zuul::Context.new.to_context.should be_nil
    end

    it "should return the class for a class context" do
      Zuul::Context.new('Context', nil).to_context.should == Context
    end

    it "should return the instance for an instance context" do
      obj = Context.create(:name => "Test Context")
      context = Zuul::Context.new('Context', obj.id).to_context
      context.should be_an_instance_of(Context)
      context.id.should == obj.id
    end
  end

  describe "#instance?" do
    it "should return false for a nil context" do
      Zuul::Context.new.instance?.should be_false
    end

    it "should return false for a class context" do
      Zuul::Context.new('Context', nil).instance?.should be_false
    end

    it "should return true for an instance context" do
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).instance?.should be_true
    end
  end

  describe "#class?" do
    it "should return false for a nil context" do
      Zuul::Context.new.class?.should be_false
    end

    it "should return true for a class context" do
      Zuul::Context.new('Context', nil).class?.should be_true
    end

    it "should return false for an instance context" do
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).class?.should be_false
    end
  end

  describe "#global?" do
    it "should return true for a nil context" do
      Zuul::Context.new.global?.should be_true
    end

    it "should return false for a class context" do
      Zuul::Context.new('Context', nil).global?.should be_false
    end

    it "should return false for an instance context" do
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).global?.should be_false
    end

    it "should be aliased to #nil? for deprecation and compatibility" do
      Zuul::Context.new.nil?.should be_true
      Zuul::Context.new('Context', nil).nil?.should be_false
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).nil?.should be_false
    end
  end

  describe "#==" do
    it "should return true if the classes and ids are equal" do
      obj = Context.create(:name => "Test Context")
      
      Zuul::Context.new.should == Zuul::Context.new
      Zuul::Context.new('Context', nil).should == Zuul::Context.new('Context', nil)
      Zuul::Context.new('Context', obj.id).should == Zuul::Context.new('Context', obj.id)
    end

    it "should return false if the classes are not equal" do
      obj = Context.create(:name => "Test Context")
      
      Zuul::Context.new.should_not == Zuul::Context.new('Context', nil)
      Zuul::Context.new('Context', nil).should_not == Zuul::Context.new('OtherContext', nil)
    end

    it "should return false if the ids are not equal" do
      obj1 = Context.create(:name => "Test Context One")
      obj2 = Context.create(:name => "Test Context Two")
      
      Zuul::Context.new('Context', obj1.id).should_not == Zuul::Context.new('Context', nil)
      Zuul::Context.new('Context', obj1.id).should_not == Zuul::Context.new('Context', obj2.id)
    end
  end

  describe "#<=" do
    context "with a global context" do
      let(:context) { Zuul::Context.new }
      
      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return true" do
          expect(context <= kontext).to be_true
        end
      end
      
      context "when compared to a class context" do
        let(:kontext) { Zuul::Context.new('Context') }
        
        it "should return false" do
          expect(context <= kontext).to be_false
        end
      end
      
      context "when compared to an instance context" do
        let(:kontext) do
          obj = Context.create(:name => "Test Context")
          Zuul::Context.new('Context', obj.id)
        end
        
        it "should return false" do
          expect(context <= kontext).to be_false
        end
      end
    end
    
    context "with a class context" do
      let(:context) { Zuul::Context.new('Context') }
      
      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return true" do
          expect(context <= kontext).to be_true
        end
      end
      
      context "when compared to a class context" do
        context "with the same class" do
          let(:kontext) { Zuul::Context.new('Context') }
          
          it "should return true" do
            expect(context <= kontext).to be_true
          end
        end
        
        context "with a different class" do
          let(:kontext) { Zuul::Context.new('OtherContext') }
          
          it "should return false" do
            expect(context <= kontext).to be_false
          end
        end
      end

      context "when compared to an instance context" do
        context "with the same class" do
          let(:kontext) do
            obj = Context.create(:name => "Test Context")
            Zuul::Context.new('Context', obj.id)
          end
          
          it "should return false" do
            expect(context <= kontext).to be_false
          end
        end
        
        context "with a different class" do
          let(:kontext) do
            obj = ZuulModels::Context.create(:name => "Test Context")
            Zuul::Context.new('OtherContext', obj.id)
          end
          
          it "should return false" do
            expect(context <= kontext).to be_false
          end
        end
      end
    end
    
    context "with an instance context" do
      let(:obj) { Context.create(:name => "Test Context") }
      let(:context) do
        Zuul::Context.new('Context', obj.id)
      end

      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return true" do
          expect(context <= kontext).to be_true
        end
      end
      
      context "when compared to a class context" do
        context "with the same class" do
          let(:kontext) { Zuul::Context.new('Context') }
          
          it "should return true" do
            expect(context <= kontext).to be_true
          end
        end
        
        context "with a different class" do
          let(:kontext) { Zuul::Context.new('OtherContext') }
          
          it "should return false" do
            expect(context <= kontext).to be_false
          end
        end
      end
      
      context "when compared to an instance context" do
        context "with the same class" do
          context "with the same id" do
            let(:kontext) do
              Zuul::Context.new('Context', obj.id)
            end
            
            it "should return true" do
              expect(context <= kontext).to be_true
            end
          end
          
          context "with a different id" do
            let(:kontext) do
              other_obj = Context.create(:name => "Other Context")
              Zuul::Context.new('Context', other_obj.id)
            end

            it "should return false" do
              expect(context <= kontext).to be_false
            end
          end
        end
        
        context "with a different class" do
          let(:kontext) do
            Zuul::Context.new('OtherContext', obj.id)
          end
          
          it "should return false" do
            expect(context <= kontext).to be_false
          end
        end
      end
    end
  end

  describe "#>=" do
    context "with a global context" do
      let(:context) { Zuul::Context.new }
      
      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return true" do
          expect(context >= kontext).to be_true
        end
      end
      
      context "when compared to a class context" do
        let(:kontext) { Zuul::Context.new('Context') }
        
        it "should return true" do
          expect(context >= kontext).to be_true
        end
      end
      
      context "when compared to an instance context" do
        let(:kontext) do
          obj = Context.create(:name => "Test Context")
          Zuul::Context.new('Context', obj.id)
        end
        
        it "should return true" do
          expect(context >= kontext).to be_true
        end
      end
    end
    
    context "with a class context" do
      let(:context) { Zuul::Context.new('Context') }
      
      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return false" do
          expect(context >= kontext).to be_false
        end
      end
      
      context "when compared to a class context" do
        context "with the same class" do
          let(:kontext) { Zuul::Context.new('Context') }
          
          it "should return true" do
            expect(context >= kontext).to be_true
          end
        end
        
        context "with a different class" do
          let(:kontext) { Zuul::Context.new('OtherContext') }
          
          it "should return false" do
            expect(context >= kontext).to be_false
          end
        end
      end

      context "when compared to an instance context" do
        context "with the same class" do
          let(:kontext) do
            obj = Context.create(:name => "Test Context")
            Zuul::Context.new('Context', obj.id)
          end
          
          it "should return true" do
            expect(context >= kontext).to be_true
          end
        end
        
        context "with a different class" do
          let(:kontext) do
            obj = ZuulModels::Context.create(:name => "Test Context")
            Zuul::Context.new('OtherContext', obj.id)
          end
          
          it "should return false" do
            expect(context >= kontext).to be_false
          end
        end
      end
    end
    
    context "with an instance context" do
      let(:obj) { Context.create(:name => "Test Context") }
      let(:context) do
        Zuul::Context.new('Context', obj.id)
      end

      context "when compared a global context" do
        let(:kontext) { Zuul::Context.new }
        
        it "should return false" do
          expect(context >= kontext).to be_false
        end
      end
      
      context "when compared to a class context" do
        context "with the same class" do
          let(:kontext) { Zuul::Context.new('Context') }
          
          it "should return false" do
            expect(context >= kontext).to be_false
          end
        end
        
        context "with a different class" do
          let(:kontext) { Zuul::Context.new('OtherContext') }
          
          it "should return false" do
            expect(context >= kontext).to be_false
          end
        end
      end
      
      context "when compared to an instance context" do
        context "with the same class" do
          context "with the same id" do
            let(:kontext) do
              Zuul::Context.new('Context', obj.id)
            end
            
            it "should return true" do
              expect(context >= kontext).to be_true
            end
          end
          
          context "with a different id" do
            let(:kontext) do
              other_obj = Context.create(:name => "Other Context")
              Zuul::Context.new('Context', other_obj.id)
            end

            it "should return false" do
              expect(context >= kontext).to be_false
            end
          end
        end
        
        context "with a different class" do
          let(:kontext) do
            Zuul::Context.new('OtherContext', obj.id)
          end
          
          it "should return false" do
            expect(context >= kontext).to be_false
          end
        end
      end
    end
  end

  describe "#type" do
    it "should return :nil for a nil context" do
      Zuul::Context.new.type.should == :nil
    end

    it "should return :class for a class context" do
      Zuul::Context.new('Context', nil).type.should == :class
    end

    it "should return :instance for an instance context" do
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).type.should == :instance
    end
  end
  
  describe "#type_s" do
    it "should return 'global' for a nil context" do
      Zuul::Context.new.type_s.should == 'global'
    end

    it "should return class name for a class context" do
      Zuul::Context.new('Context', nil).type_s.should == 'Context'
    end

    it "should return class name and ID for an instance context" do
      obj = Context.create(:name => "Test Context")
      Zuul::Context.new('Context', obj.id).type_s.should == "Context(#{obj.id})"
    end
  end
end
