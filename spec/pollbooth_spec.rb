require 'spec_helper'

describe AsyncCallbacks do
  before { AsyncCallbacks::Worker.auto_drain = false }

  context "when the AsyncCallbacks module is not included" do
    let(:model) do
      define_constant :TestModel do
        include Mongoid::Document

        field :field_1

        after_create :callback1

        def callback1
          self.update_attributes(:field_1 => 'bye')
        end
      end
    end

    it 'runs callbacks synchronously' do
      instance = model.create(:field_1 => 'hi')

      instance.field_1.should == 'bye'
    end
  end

  context "when the AsyncCallbacks module is included" do
    context "after create callbacks" do
      let(:model) do
        define_constant :TestModel do
          include Mongoid::Document
          include AsyncCallbacks

          field :field_1
          field :field_2
          field :field_3

          after_create :callback1
          after_create :callback2
          after_create do
            $field_3_updated = true
          end

          def callback1
            $field_1_updated = true
          end

          def callback2
            $field_2_updated = true
          end
        end
      end

      it 'runs callbacks asynchronously' do
        instance = model.create(:field_1 => 'hi')

        $field_1_updated.should == nil

        AsyncCallbacks::Worker.drain

        $field_1_updated.should == true
        $field_2_updated.should == true
        $field_3_updated.should == true
      end
    end

    context "after update callbacks" do
      let(:model) do
        define_constant :TestModel do
          include Mongoid::Document
          include AsyncCallbacks

          field :field_1
          field :field_2
          field :field_3

          after_update :callback1

          def callback1
            $value_changed = self.field_1_changed?
          end
        end
      end

      before { $value_changed = false }

      it 'tracks changed values' do
        instance = model.create(:field_1 => 'hi')
        instance.update_attributes(:field_1 => 'bye')

        $value_changed.should == false

        AsyncCallbacks::Worker.drain

        $value_changed.should == true
      end
    end

    context "before callbacks" do
      let(:model) do
        define_constant :TestModel do
          include Mongoid::Document
          include AsyncCallbacks

          field :field_1
          field :field_2
          field :field_3

          before_create :callback1

          def callback1
            self.field_1 = 'bye'
          end
        end
      end

      it 'runs callbacks synchronously' do
        instance = model.create

        instance.field_1.should == 'bye'
      end
    end

    context "around callbacks" do
      let(:model) do
        define_constant :TestModel do
          include Mongoid::Document
          include AsyncCallbacks

          field :field_1
          field :field_2
          field :field_3

          around_create :callback1

          def callback1
            self.field_1 = 'bye'
            yield
            self.update_attributes(:field_2 => 'bye')
          end
        end
      end

      it 'runs callbacks synchronously' do
        instance = model.create

        instance.field_1.should == 'bye'
        instance.field_2.should == 'bye'
      end
    end
  end

  context 'with promiscuous remote observers' do
    let(:model) do
      define_constant :TestModel do
        include Promiscuous::Subscriber::Model::Observer
        include AsyncCallbacks

        attr_accessor :field_1

        after_create :callback1

        def callback1
          $callback_value = self.field_1
        end
      end
    end

    it 'runs callbacks asynchronously' do
      instance = model.new
      instance.field_1 = 'value'
      instance.run_callbacks :create

      $callback_value.should be_nil

      AsyncCallbacks::Worker.drain

      $callback_value.should == 'value'
    end
  end

  context 'with embedded documents' do
    let!(:model) do
      define_constant :TestModel do
        include Mongoid::Document

        embeds_many :test_embedded_many_models
        embeds_one  :test_embedded_one_model
      end
    end

    let!(:embedded_many_model) do
      define_constant :TestEmbeddedManyModel do
        include Mongoid::Document
        include AsyncCallbacks
        embedded_in :test_model

        after_create :callback1

        field :field_1

        def callback1
          $embedded_many_value = self.field_1
        end
      end
    end

    let!(:embedded_one_model) do
      define_constant :TestEmbeddedOneModel do
        include Mongoid::Document
        include AsyncCallbacks
        embedded_in :test_model
        embeds_one  :test_embedded_in_embedded

        after_create :callback1

        field :field_1

        def callback1
          $embedded_one_value  = self.field_1
        end
      end
    end

    let!(:embedded_in_embedded) do
      define_constant :TestEmbeddedInEmbedded do
        include Mongoid::Document
        include AsyncCallbacks
        embedded_in :test_embedded_one_model

        after_create :callback1

        field :field_1

        def callback1
          $embedded_in_embedded_value  = self.field_1
        end
      end
    end

    it 'runs callbacks asynchronously for embeds many' do
      instance = model.create
      instance.test_embedded_many_models.create(:field_1 => 'value')

      $embedded_many_value.should be_nil

      AsyncCallbacks::Worker.drain

      $embedded_many_value.should == 'value'
    end

    it 'runs callbacks asynchronously for embeds one' do
      instance = model.create
      instance.create_test_embedded_one_model(:field_1 => 'value')

      $embedded_one_value.should be_nil

      AsyncCallbacks::Worker.drain

      $embedded_one_value.should  == 'value'
    end

    it 'runs callbacks asynchronously for an embedded doc within another embedded doc' do
      instance = model.create
      embeds_one_instance = instance.create_test_embedded_one_model(:field_1 => 'value')
      embeds_one_instance.create_test_embedded_in_embedded(:field_1 => 'value')

      $embedded_in_embedded_value.should be_nil

      AsyncCallbacks::Worker.drain

      $embedded_in_embedded_value.should == 'value'
    end
  end

end
