require 'xcodeproj'

project_path = '/Users/muratcan/imandefterim/imandefterim/imandefterim.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'imandefterim'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Target #{target_name} not found"
  exit 1
end

# Navigate to groups: imandefterim -> Views -> Notes
local_group = project.main_group['imandefterim']['Views']['Notes']

if local_group.nil?
  puts "Group path not found"
  # Fallback: try to find 'Notes' group recursively
  local_group = project.main_group.recursive_children.find { |c| c.name == 'Notes' && c.isa == 'PBXGroup' }
end

if local_group.nil?
  puts "Notes group not found"
  exit 1
end

file_name = 'FolderSelectionSheet.swift'
# Check if already exists
if local_group.files.any? { |f| f.path == file_name || f.name == file_name }
  puts "File already in project"
else
  file_ref = local_group.new_reference(file_name)
  target.add_file_references([file_ref])
  project.save
  puts "Added #{file_name} to project"
end
