require 'nokogiri'
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
  measures_path = File.expand_path("../../../measures/", __FILE__ )
  measure_folders_name = Dir.entries(measures_path).select {|entry| File.directory? File.join(measures_path,entry) and !(entry =='.' || entry == '..') }
  measure_folders_name.each do |measure_folder|
    # read the measure.xml file, get measure's metadata
    measure_xml = File.join(measures_path,measure_folder,'measure.xml')
    data = File.open(measure_xml) { |f| Nokogiri::XML(f) }
    # get measure's display name
    measure_name = data.xpath("//display_name").first.content
    # get measure's ruby class name
    class_name = data.xpath("//class_name").first.content
    # get parameter name list
    para_names = []
    data.xpath("measure//arguments//argument//name").each{|ele| para_names << ele.content}
    measure_list[measure_name] = {}
    measure_list[measure_name]['measure_dir_name'] = File.join(measures_path, measure_folder)
    measure_list[measure_name]['class_name'] = class_name
    measure_list[measure_name]['para_names'] = para_names
    # puts JSON.pretty_generate(measure_list)
  end

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