# Adds ios/AtlasWidget/PrivacyInfo.xcprivacy to the AtlasWidget target's
# resources. Safe to run again.
require 'xcodeproj'

project = Xcodeproj::Project.open(File.expand_path('../ios/Runner.xcodeproj', __dir__))
widget = project.targets.find { |t| t.name == 'AtlasWidget' } or abort 'no AtlasWidget target'
group = project.main_group['AtlasWidget'] or abort 'no AtlasWidget group'
if group.files.any? { |f| f.path == 'PrivacyInfo.xcprivacy' }
  puts 'already there'
  exit
end
ref = group.new_reference('PrivacyInfo.xcprivacy')
widget.resources_build_phase.add_file_reference(ref)
project.save
puts 'added'
