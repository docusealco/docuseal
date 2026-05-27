# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'nokogiri'
require 'rexml/document'
require 'fileutils'

module TwitterCldr
  module Resources
    module Requirements

      class PomManager
        class Dep
          attr_reader :pom, :group_id, :artifact_id, :version

          def initialize(pom, group_id, artifact_id, version)
            @pom = pom
            @group_id = group_id
            @artifact_id = artifact_id
            @version = version
          end

          def path
            @path ||= begin
              sub_path = File.join(*group_id.split('.'), artifact_id, version)

              pom.classpath.find do |cp|
                cp.include?(sub_path)
              end
            end
          end
        end

        BLANK_POM = <<~END.freeze
          <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
            <modelVersion>4.0.0</modelVersion>

            <groupId>com.mycompany.app</groupId>
            <artifactId>my-app</artifactId>
            <version>1.0-SNAPSHOT</version>

            <properties>
              <maven.compiler.source>1.9</maven.compiler.source>
              <maven.compiler.target>1.9</maven.compiler.target>
            </properties>

            <dependencies>
            </dependencies>
          </project>
        END

        DEPENDENCY_TEMPLATE = <<~END.freeze
          <dependency>
            <groupId>%{group_id}</groupId>
            <artifactId>%{artifact_id}</artifactId>
            <version>%{version}</version>
          </dependency>
        END

        attr_reader :pom_file, :path

        def initialize(pom_file)
          @pom_file = pom_file
          @path = File.dirname(pom_file)
        end

        def add_dependency(group_id, artifact_id, version)
          existing_dep = (contents / 'dependencies' / 'dependency').find do |dep|
            (dep / 'groupId').text == group_id && (dep / 'artifactId').text == artifact_id
          end

          existing_dep.remove if existing_dep

          dep = DEPENDENCY_TEMPLATE % {
            group_id: group_id,
            artifact_id: artifact_id,
            version: version
          }

          (contents / 'dependencies').first.add_child(
            Nokogiri::XML(dep) / 'dependency'
          )
        end

        def install
          save
          mvn('install')
        end

        def get(group_id, artifact_id)
          dep = (contents / 'dependencies' / 'dependency').find do |dep|
            (dep / 'groupId').text == group_id && (dep / 'artifactId').text == artifact_id
          end

          Dep.new(self, group_id, artifact_id, (dep / 'version').text)
        end

        def classpath
          @classpath ||= mvn('dependency:build-classpath')
            .split("\n")
            .map(&:strip)
            .reject { |line| line =~ /\[[^\]]+\]/ }
            .first
            .split(':')
        end

        def require_jar(group_id, artifact_id)
          require get(group_id, artifact_id).path
        end

        private

        def contents
          @contents ||= if File.exist?(pom_file)
            Nokogiri::XML(File.read(pom_file)) do |config|
              config.options = Nokogiri::XML::ParseOptions::NOBLANKS
            end
          else
            Nokogiri::XML(BLANK_POM) do |config|
              config.options = Nokogiri::XML::ParseOptions::NOBLANKS
            end
          end
        end

        def save
          FileUtils.mkdir_p(File.dirname(pom_file))

          File.open(pom_file, 'w+') do |f|
            formatter.write(REXML::Document.new(contents.to_xml), f)
          end
        end

        def formatter
          @formatter ||= begin
            REXML::Formatters::Pretty.new(2).tap do |fmt|
              fmt.compact = true
            end
          end
        end

        def mvn(cmd)
          Dir.chdir(path) { `mvn #{cmd}` }
        end
      end

    end
  end
end
