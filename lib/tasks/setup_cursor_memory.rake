# Creates a memory-bank/ folder with Markdown files to document the project
# Adds a .cursor/rules file used by the Cursor AI agent

namespace :cursor do # namespace is a way to group related tasks together
  desc "Set up Cursor's memory-bank/ folder and .cursor/rules file" # desc is a way to describe the task
  task setup_memory_bank: :environment do # :environment is a way to load the Rails environment. So you have access to Rails.root, models, etc.
    require "fileutils" # fileutils is a Ruby library that provides a way to manipulate files and directories

    root = Rails.root
    memory_dir = root.join("memory-bank")
    cursor_dir = root.join(".cursor")

    core_files = {
      "project_brief.md"    => "# project_brief.md\n\n> Describe the project scope, goals, and foundational ideas here.",
      "product_context.md"  => "# product_context.md\n\n> Who is this for? What problems does it solve? UX goals.",
      "system_patterns.md"  => "# system_patterns.md\n\n> Architecture decisions, design patterns, and system structure.",
      "tech_context.md"     => "# tech_context.md\n\n> Tech stack, setup, constraints, dependencies.",
      "active_context.md"   => "# active_context.md\n\n> What we're doing now, open threads, recent changes.",
      "progress.md"        => "# progress.md\n\n> What's done, what's next, known issues."
    }

    # Create memory-bank/ directory and files
    puts "📁 Creating memory-bank/ structure..."
    FileUtils.mkdir_p(memory_dir) # mkdir_p doesn't create or override existing directories

    core_files.each do |filename, content|
      path = memory_dir.join(filename)
      unless File.exist?(path) # Skips if file already exists
        File.write(path, content)
        puts "✅ Created #{filename}"
      else
        puts "⏩ Skipped #{filename} (already exists)"
      end
    end

    # Create memory-bank/README.md
    readme_path = memory_dir.join("README.md")
    unless File.exist?(readme_path)
      File.write(readme_path, "# Memory Bank\n\nThis folder contains long-term documentation used by the Cursor AI agent.")
      puts "✅ Created README.md"
    else
      puts "⏩ Skipped README.md (already exists)"
    end

    # Create .cursor/rules
    puts "📘 Creating .cursor/rules..."
    FileUtils.mkdir_p(cursor_dir)
    rules_path = cursor_dir.join("rules")

    unless File.exist?(rules_path)
      File.write(rules_path, "# Cursor Rule\n\nThis folder contains long-term documentation used by the Cursor AI agent.")
      puts "✅ Created .cursor/rules"
    else
      puts "⏩ Skipped .cursor/rules (already exists)"
    end

    puts "\n🎉 Cursor Memory Bank and rules file are ready!"
  end
end
