# frozen_string_literal: true

require 'rails_helper'
require 'templates/field_detection'
require 'templates/field_detection/config_based'

RSpec.describe Templates::FieldDetection do
  before { described_class.reset! }

  after { described_class.reset! }

  describe '.register' do
    it 'stores a handler by downcased name' do
      handler = ->(_template, _documents) { [] }
      described_class.register('MyAlgo', handler)

      expect(described_class.registered_scripts).to include('myalgo' => handler)
    end

    it 'strips whitespace from name' do
      handler = ->(_template, _documents) { [] }
      described_class.register('  spaced  ', handler)

      expect(described_class.registered_scripts).to include('spaced' => handler)
    end
  end

  describe '.available_algorithms' do
    it 'returns registered scripts merged with external YAML profiles' do
      handler = ->(_template, _documents) { [] }
      described_class.register('script_algo', handler)

      allow(described_class).to receive(:external_algorithms).and_return(
        'yaml_profile' => { 'fields' => [] }
      )

      algos = described_class.available_algorithms
      expect(algos).to include('script_algo' => handler)
      expect(algos).to include('yaml_profile' => { 'fields' => [] })
    end
  end

  describe '.profile_names' do
    it 'returns sorted list of all algorithm names' do
      described_class.register('zebra', ->(_t, _d) { [] })
      described_class.register('alpha', ->(_t, _d) { [] })

      allow(described_class).to receive(:external_algorithms).and_return(
        'middle' => { 'fields' => [] }
      )

      expect(described_class.profile_names).to eq(%w[alpha middle zebra])
    end
  end

  describe '.load_scripts!' do
    it 'loads .rb files from SCRIPTS_DIR' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'test_algo.rb'), <<~RUBY)
          Templates::FieldDetection.register('test_algo', ->(_t, _d) { :loaded })
        RUBY

        stub_const('Templates::FieldDetection::SCRIPTS_DIR', dir)
        described_class.reset!
        described_class.load_scripts!

        expect(described_class.registered_scripts).to include('test_algo')
        expect(described_class.registered_scripts['test_algo'].call(nil, nil)).to eq(:loaded)
      end
    end

    it 'logs warning and continues on script error' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'bad_script.rb'), 'raise "boom"')
        File.write(File.join(dir, 'good_script.rb'), <<~RUBY)
          Templates::FieldDetection.register('good', ->(_t, _d) { :ok })
        RUBY

        stub_const('Templates::FieldDetection::SCRIPTS_DIR', dir)
        described_class.reset!

        allow(Rails.logger).to receive(:warn)
        described_class.load_scripts!

        expect(Rails.logger).to have_received(:warn).with(/Failed to load script.*bad_script\.rb.*boom/)
        expect(described_class.registered_scripts).to include('good')
        expect(described_class.registered_scripts).not_to include('bad_script')
      end
    end

    it 'skips loading when SCRIPTS_DIR does not exist' do
      stub_const('Templates::FieldDetection::SCRIPTS_DIR', '/nonexistent/path')
      described_class.reset!

      expect { described_class.load_scripts! }.not_to raise_error
    end
  end

  describe '.external_algorithms' do
    it 'parses YAML files from CONFIG_DIR' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'profile_x.yml'), <<~YAML)
          submitters:
            - name: signer
          fields:
            - name: sig
              type: signature
        YAML

        stub_const('Templates::FieldDetection::CONFIG_DIR', dir)

        algos = described_class.external_algorithms
        expect(algos).to include('profile_x')
        expect(algos['profile_x']).to be_a(Hash)
        expect(algos['profile_x']['fields'].first['name']).to eq('sig')
      end
    end

    it 'returns empty hash when CONFIG_DIR does not exist' do
      stub_const('Templates::FieldDetection::CONFIG_DIR', '/nonexistent/path')

      expect(described_class.external_algorithms).to eq({})
    end

    it 'skips malformed YAML files' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'bad.yml'), ': invalid: yaml: [')
        File.write(File.join(dir, 'good.yml'), "submitters:\n  - name: s\n")

        stub_const('Templates::FieldDetection::CONFIG_DIR', dir)

        algos = described_class.external_algorithms
        expect(algos).to include('good')
        expect(algos).not_to include('bad')
      end
    end
  end

  describe '.call' do
    it 'raises ArgumentError for unknown algorithm' do
      expect { described_class.call(instance_double(Template), 'nonexistent') }
        .to raise_error(ArgumentError, /Unknown algorithm: 'nonexistent'/)
    end

    it 'invokes registered script handler' do
      template = instance_double(Template)
      documents = instance_double(ActiveRecord::Relation)
      handler = ->(_t, _d) { :script_result }

      described_class.register('my_script', handler)

      result = described_class.call(template, 'my_script', documents)
      expect(result).to eq(:script_result)
    end

    it 'dispatches YAML profile to ConfigBased.call' do
      template = instance_double(Template)
      documents = instance_double(ActiveRecord::Relation)
      config = { 'fields' => [], 'submitters' => [] }

      allow(described_class).to receive(:external_algorithms).and_return(
        'yaml_test' => config
      )

      allow(Templates::FieldDetection::ConfigBased).to receive(:call)
        .with(template, config, documents)
        .and_return([])

      result = described_class.call(template, 'yaml_test', documents)
      expect(result).to eq([])
      expect(Templates::FieldDetection::ConfigBased).to have_received(:call)
        .with(template, config, documents)
    end

    it 'is case-insensitive for algorithm names' do
      handler = ->(_t, _d) { :found }
      described_class.register('CaseSensitive', handler)

      result = described_class.call(instance_double(Template), 'casesensitive')
      expect(result).to eq(:found)
    end
  end
end
