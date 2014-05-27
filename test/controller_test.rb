require 'test_helper'

describe Lotus::Controller do
  describe '.configuration' do
    before do
      class ConfigurationController
        include Lotus::Controller
      end
    end

    after do
      Object.send(:remove_const, :ConfigurationController)
    end

    it 'exposes class configuration' do
      Lotus::Controller.configuration.must_be_kind_of(Lotus::Controller::Configuration)
    end

    it 'handles exceptions by default' do
      Lotus::Controller.configuration.handle_exceptions.must_equal(true)
    end

    it 'inheriths the configuration from the framework' do
      expected = Lotus::Controller.configuration
      actual   = ConfigurationController.configuration

      actual.handled_exceptions.must_equal(expected.handled_exceptions)
    end
  end

  describe '.configure' do
    after do
      Lotus::Controller.configuration.handle_exceptions = true
    end

    it 'allows to configure the framework' do
      Lotus::Controller.class_eval do
        configure do
          handle_exceptions false
        end
      end

      Lotus::Controller.configuration.handle_exceptions.must_equal(false)
    end

    it 'allows to override one value' do
      Lotus::Controller.class_eval do
        configure do
          handle_exception ArgumentError => 400
        end

        configure do
          handle_exception NotImplementedError => 418
        end
      end

      Lotus::Controller.configuration.handled_exceptions.must_include(ArgumentError)
    end
  end

  describe '.action' do
    it 'creates an action for the given name' do
      action = TestController::Index.new
      action.call({name: 'test'})
      action.xyz.must_equal 'test'
    end

    it "raises an error when the given name isn't a valid Ruby identifier" do
      -> {
        class Controller
          include Lotus::Controller

          action 12 do
            def call(params)
            end
          end
        end
      }.must_raise TypeError
    end

    describe 'when configured with a custom module' do
      before do
        module CustomActionModule
          def self.included(base)
            base.extend ClassMethods
          end

          module ClassMethods
            def configuration=(configuration)
              @configuration = configuration
            end
          end

          def call(params)
            [200, {}, "Custom"]
          end
        end

        Lotus::Controller.class_eval do
          configure do
            action_module CustomActionModule
          end
        end

        class CustomController
          include Lotus::Controller

          action 'Index' do
            def call(params)
              super
            end
          end
        end
      end

      after do
        Lotus::Controller.class_eval do
          configure do
            action_module ::Lotus::Action
          end
        end

        Object.send(:remove_const, :CustomActionModule)
        Object.send(:remove_const, :CustomController)
      end

      it 'includes it' do
        _, _, body = CustomController::Index.new.call({})
        body.must_equal "Custom"
      end
    end
  end
end
