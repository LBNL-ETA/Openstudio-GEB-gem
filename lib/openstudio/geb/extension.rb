require 'openstudio/extension'

module OpenStudio
  module Geb
    class Extension < OpenStudio::Extension::Extension

      # Override parent class
      def initialize
        super
        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end

      # Return the absolute path of the measures or nil if there is none, can be used when configuring OSWs
      def measures_dir
        return File.absolute_path(File.join(@root_dir, 'lib', 'measures'))
      end

      # Relevant files such as weather data, design days, etc.
      # Return the absolute path of the files or nil if there is none, used when configuring OSWs
      def files_dir
        return File.absolute_path(File.join(@root_dir, 'lib', 'files'))
      end

      # Doc templates are common files like copyright files which are used to update measures and other code
      # Doc templates will only be applied to measures in the current repository
      # Return the absolute path of the doc templates dir or nil if there is none
      def doc_templates_dir
        return File.absolute_path(File.join(@root_dir, 'doc_templates'))
      end

    end
  end
end