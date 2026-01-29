require 'xcodeproj'

project_path = 'imandefterim.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'imandefterim'
target = project.targets.find { |t| t.name == target_name }

file_name = 'DailyVerseService.swift'

# Find the file reference
file_ref = project.files.find { |f| f.path == file_name || f.path.end_with?("/#{file_name}") }

if file_ref
  # Remove from target
  target.source_build_phase.remove_file_reference(file_ref)
  
  # Remove from group (we need to find which group it is in, or just remove from hierarchy)
  file_ref.remove_from_project
  
  puts "Removed #{file_name} from project."
else
  # Try to search recursively in groups if main file list check failed (though project.files should cover it)
  puts "File reference for #{file_name} not found in root, searching groups..."
  
  # Helper to recursively find and remove
  removed = false
  project.groups.each do |group|
    if (ref = group.recursive_children.find { |child| child.isa == 'PBXFileReference' && child.name == file_name }) ||
       (ref = group.recursive_children.find { |child| child.isa == 'PBXFileReference' && child.path && child.path.end_with?(file_name) })
       
       target.source_build_phase.remove_file_reference(ref)
       ref.remove_from_project
       puts "Removed #{file_name} from group #{group.name}"
       removed = true
       break
    end
  end
  
  puts "File not found in project." unless removed
end

project.save
puts "Project saved!"
