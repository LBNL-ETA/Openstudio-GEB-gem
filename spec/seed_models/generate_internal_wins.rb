# codes to generate internal windows in the MediumOffice model

require 'openstudio'
require 'json'

# # create runner with empty OSW
# osw = OpenStudio::WorkflowJSON.new
# runner = OpenStudio::Measure::OSRunner.new(osw)
#
# load the test model
translator = OpenStudio::OSVersion::VersionTranslator.new
path = "#{File.dirname(__FILE__)}/MediumOffice-90.1-2010-ASHRAE 169-2013-5A.osm"
# path = "#{File.dirname(__FILE__)}/SmallHotel-2A.osm"
model = translator.loadModel(path)
model = model.get

# add internal window to an indoor wall
wall1 = model.getSurfaceByName("Core_top_ZN_5_Wall_West").get
win_cons = model.getConstructionByName("U 1.17 SHGC 0.49 Sgl Ref-D Clr 6mm").get
wall1.setWindowToWallRatio(0.2)
wall1.subSurfaces.sort.each do |sub_surf|
  sub_surf.setSubSurfaceType('FixedWindow')
  sub_surf.setConstruction(win_cons)
  vertices = sub_surf.vertices
  adj_sub_surf = OpenStudio::Model::SubSurface.new(vertices.reverse, model)
  adj_sub_surf.setSubSurfaceType('FixedWindow')
  adj_sub_surf.setConstruction(win_cons)
  adj_sub_surf.setSurface(wall1.adjacentSurface.get)
  sub_surf.setAdjacentSubSurface(adj_sub_surf)
end

wall2 = model.getSurfaceByName("Core_mid_ZN_5_Wall_North").get
wall2.setWindowToWallRatio(0.2)
wall2.subSurfaces.sort.each do |sub_surf|
  sub_surf.setSubSurfaceType('FixedWindow')
  sub_surf.setConstruction(win_cons)
  vertices = sub_surf.vertices
  adj_sub_surf = OpenStudio::Model::SubSurface.new(vertices.reverse, model)
  adj_sub_surf.setSubSurfaceType('FixedWindow')
  adj_sub_surf.setConstruction(win_cons)
  adj_sub_surf.setSurface(wall2.adjacentSurface.get)
  sub_surf.setAdjacentSubSurface(adj_sub_surf)
end

wall3 = model.getSurfaceByName("Core_bot_ZN_5_Wall_West").get
wall3.setWindowToWallRatio(0.2)
wall3.subSurfaces.sort.each do |sub_surf|
  sub_surf.setSubSurfaceType('FixedWindow')
  sub_surf.setConstruction(win_cons)
  vertices = sub_surf.vertices
  adj_sub_surf = OpenStudio::Model::SubSurface.new(vertices.reverse, model)
  adj_sub_surf.setSubSurfaceType('FixedWindow')
  adj_sub_surf.setConstruction(win_cons)
  adj_sub_surf.setSurface(wall3.adjacentSurface.get)
  sub_surf.setAdjacentSubSurface(adj_sub_surf)
end


# run model
# save the model to test output directory
output_file_path = "#{File.dirname(__FILE__)}//output/medium_office_with_internal_windows.osm"
model.save(output_file_path, true)

