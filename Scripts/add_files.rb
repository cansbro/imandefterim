require 'xcodeproj'

project_path = 'imandefterim.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'imandefterim'
target = project.targets.find { |t| t.name == target_name }

if target.nil?
  puts "Target #{target_name} not found!"
  exit 1
end

group_path = ['imandefterim', 'Views', 'Settings']
group = project.main_group
group_path.each do |name|
  group = group[name]
  if group.nil?
    puts "Group #{name} not found in #{group_path}!"
    exit 1
  end
end

files_to_add = [
  'SubscriptionManagementView.swift'
]

files_to_add.each do |file_name|
  # Check if file is already in group
  if group.find_file_by_path(file_name)
    puts "#{file_name} already in project, skipping..."
    next
  end

  file_ref = group.new_reference(file_name)
  target.add_file_references([file_ref])
  puts "Added #{file_name} to project and target #{target_name}"
end

project.save
puts "Project saved!"
