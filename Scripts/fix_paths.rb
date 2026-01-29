require 'xcodeproj'

project_path = 'imandefterim.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Navigate to imandefterim > Views > AI
group = project.main_group['imandefterim']['Views']['AI']

if group.nil?
  puts "Group AI not found!"
  exit 1
end

# Fix the group path
# It seems the group was created without a path, so it defaults to parent's path.
# We need to set it to 'AI' so it looks inside the AI subdirectory.
puts "Current group path: #{group.path}"
group.path = 'AI'
puts "New group path: #{group.path}"

# Verify file references match simple names now that group path is set
group.files.each do |file|
  puts "File ref: #{file.path}"
  # If file path was absolute or weird, reset it to just filename
  file.path = File.basename(file.path)
end

project.save
puts "Project saved with fixed paths!"
