# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# require 'oga'
require 'json'

# load openstudio model
def safe_load_osm(model_path_string)
  model_path = OpenStudio::Path.new(model_path_string)
  if OpenStudio.exists(model_path)
    version_translator = OpenStudio::OSVersion::VersionTranslator.new
    model = version_translator.loadModel(model_path)
    if model.empty?
      OpenStudio.logFree(OpenStudio::Error, 'openstudio.model.Model', "Version translation failed for #{model_path_string}")
      return false
    else
      model = model.get
    end
  else
    OpenStudio.logFree(OpenStudio::Error, 'openstudio.model.Model', "#{model_path_string} couldn't be found")
    return false
  end
  return model
end

# get the list of available GEB measures in json format
def list_all_geb_measures
  measure_list = {}

  # get the absolute path of measures folder
  measures_dir = File.expand_path("../../../measures/", __FILE__ )

  # use partial codes from function list_measures in OS Extension Runner to get the list of measures
  # this is a temporary solution for the geb gem to be adopted by URBANopt workflow due to gem complexity
  # (previously use nokogiri/oga as dependency and it didn't work in the integration process)
  if measures_dir.nil? || measures_dir.empty?
    puts 'Measures dir is nil or empty'
    return true
  end

  # this is to accommodate a single measures dir (like most gems)
  # or a repo with multiple directories fo measures (like OpenStudio-measures)
  measures = Dir.glob(File.join(measures_dir, '**/measure.rb'))
  if measures.empty?
    # also try nested 2-deep to support openstudio-measures
    measures = Dir.glob(File.join(measures_dir, '**/**/measure.rb'))
  end
  puts "#{measures.length} MEASURES FOUND"
  puts measures.inspect
  measures.each do |measure|
    measure_name = measure.split('/')[-2]
    measure_list[measure_name] = {}
    measure_list[measure_name]['measure_dir_name'] = File.dirname(measure)
  end

=begin
  measure_folders_name = Dir.entries(measures_path).select {|entry| File.directory? File.join(measures_path,entry) and !(entry =='.' || entry == '..') }
  measure_folders_name.each do |measure_folder|
    # read the measure.xml file, get measure's metadata
    measure_xml = File.join(measures_path,measure_folder,'measure.xml')
    handle = File.open(measure_xml)
    data = Oga.parse_xml(handle)

    # get measure's display name
    measure_name = data.xpath("//display_name").first.text
    # get measure's ruby class name
    class_name = data.xpath("//class_name").first.text
    # get parameter name list
    para_names = []
    data.xpath("measure//arguments//argument//name").each{|ele| para_names << ele.text}
    measure_list[measure_name] = {}
    measure_list[measure_name]['measure_dir_name'] = File.join(measures_path, measure_folder)
    measure_list[measure_name]['class_name'] = class_name
    measure_list[measure_name]['para_names'] = para_names
    # puts JSON.pretty_generate(measure_list)
  end
=end

  return measure_list
end


# for parallel runs under Ruby 2.2.4
def get_run_env
  new_env = {}
  new_env['BUNDLER_ORIG_MANPATH'] = nil
  new_env['BUNDLER_ORIG_PATH'] = nil
  new_env['BUNDLER_VERSION'] = nil
  new_env['BUNDLE_BIN_PATH'] = nil
  new_env['RUBYLIB'] = nil
  new_env['RUBYOPT'] = nil
  new_env['GEM_PATH'] = nil
  new_env['GEM_HOME'] = nil
  new_env['BUNDLE_GEMFILE'] = nil
  new_env['BUNDLE_PATH'] = nil
  new_env['BUNDLE_WITHOUT'] = nil

  return new_env
end

def rm_old_folder_and_create_new(folder_path)
  if File.exist? folder_path
    FileUtils.rm_rf(folder_path)
    sleep(0.1)
  end

  unless File.directory?(folder_path)
    FileUtils.mkdir_p(folder_path)
  end
end

def postprocess_out_osw(outdir)

  out_osw = File.join(outdir, 'out.osw')
  raise "Cannot find file #{out_osw}" if !File.exists?(out_osw)

  result_osw = nil
  File.open(out_osw, 'r') do |f|
    result_osw = JSON::parse(f.read, :symbolize_names=>true)
  end

  if !result_osw.nil?
    if result_osw.keys.include?(:eplusout_err)
      result_osw[:eplusout_err].gsub!(/YMD=.*?,/, '')
      result_osw[:eplusout_err].gsub!(/Elapsed Time=.*?\n/, '')
      # Replace eplusout_err by a list of lines instead of a big string
      # Will make git diffing easier
      result_osw[:eplusout_err] = result_osw[:eplusout_err].split("\n")
    end

    result_osw.delete(:completed_at)
    result_osw.delete(:hash)
    result_osw.delete(:started_at)
    result_osw.delete(:updated_at)

    # Should always be true
    if (result_osw[:steps].size == 1) && (result_osw[:steps].select{|s| s[:measure_dir_name] == 'openstudio_results'}.size == 1)
      # If something went wrong, there wouldn't be results
      if result_osw[:steps][0].keys.include?(:result)
        result_osw[:steps][0][:result].delete(:completed_at)
        result_osw[:steps][0][:result].delete(:started_at)
        result_osw[:steps][0][:result].delete(:step_files)

        # Round all numbers to 2 digits to avoid excessive diffs
        # result_osw[:steps][0][:result][:step_values].each_with_index do |h, i|
        result_osw[:steps][0][:result][:step_values].each_with_index do |h, i|
          if h[:value].is_a? Float
            result_osw[:steps][0][:result][:step_values][i][:value] = h[:value].round(2)
          end
        end
      end
    end

    # The fuel cell tests produce out.osw files that are about 800 MB
    # because E+ throws a warning in the Regula Falsi routine (an E+ bug)
    # which results in about 7.5 Million times the same warning
    # So if the file size is bigger than 100 KiB, we throw out the eplusout_err
    if File.size(out_osw) > 100000
      result_osw.delete(:eplusout_err)
    end
  end

  return result_osw
end