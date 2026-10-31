# Adds the AtlasWidget WidgetKit extension to ios/Runner.xcodeproj and
# embeds it in the app. Run once from the repo root:
#   ruby tool/add_ios_widget.rb
# Safe to run again: it does nothing if the target exists.
require 'xcodeproj'

path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(path)
name = 'AtlasWidget'
if project.targets.any? { |t| t.name == name }
  puts "#{name} already there"
  exit
end

runner = project.targets.find { |t| t.name == 'Runner' }
widget = project.new_target(:app_extension, name, :ios, '17.0', nil, :swift)

group = project.main_group.new_group(name, name)
swift = group.new_reference('AtlasWidget.swift')
group.new_reference('Info.plist')
group.new_reference('AtlasWidget.entitlements')
widget.add_file_references([swift])
%w[WidgetKit SwiftUI].each do |fw|
  widget.frameworks_build_phase.add_file_reference(
    project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework", :sdk_root)
  )
end

widget.build_configurations.each do |c|
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.atlas.atlasMobile.AtlasWidget'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'AtlasWidget/Info.plist'
  s['CODE_SIGN_ENTITLEMENTS'] = 'AtlasWidget/AtlasWidget.entitlements'
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
  s['CODE_SIGN_STYLE'] = 'Automatic'
end
# The extension takes the app's version (FLUTTER_BUILD_NAME / _NUMBER)
# from Flutter's Generated.xcconfig.
gen = project.files.find { |f| f.path&.end_with?('Generated.xcconfig') }
widget.build_configurations.each { |c| c.base_configuration_reference = gen } if gen

runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end
runner_group = project.main_group.children.find { |g| g.display_name == 'Runner' }
runner_group&.new_reference('Runner.entitlements')

# Build it with the app and copy it into Runner.app/PlugIns.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.dst_subfolder_spec = '13' # PlugIns
embed.add_file_reference(widget.product_reference).settings = {
  'ATTRIBUTES' => ['RemoveHeadersOnCopy']
}
# Embedding must come before Flutter's own "Thin Binary" script runs.
phases = runner.build_phases
thin = phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  phases.delete(embed)
  phases.insert(phases.index(thin), embed)
end

project.save
puts "added #{name}"
