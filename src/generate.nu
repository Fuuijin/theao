# Read the theme configuration
let theme = open ./theme.toml

# Create the output directory if it doesn't exist
def create_dir [path: string] {
  if not ($path | path exists) {
    mkdir $path
  }
}

# Create output directories
create_dir "output"
create_dir "output/wezterm"
create_dir "output/foot"
create_dir "output/spt" 
create_dir "output/hyprland"
create_dir "output/nushell"

# Define output paths based on template name
def get_output_path [template_name: string] {
  let name = ($template_name | path basename)
  let extension = ($template_name | path split)
  let base_name = ($name | str replace --all '.template' '')
  
  if $name =~ "wezterm" {
    return "output/wezterm/colors.lua"
  } else if $name =~ "foot" {
    return "output/foot/colors.conf" 
  } else if $name =~ "spt" {
    return "output/spt/config.conf"
  } else if $name =~ "hyprland" {
    return "output/hyprland/colors.conf"
  } else if $name =~ "nushell" {
    return "output/nushell/theme.nu"
  } else {
    # Default fallback - use the original name
    return $"output/($base_name)($extension)"
  }
}

# Process a single template
def process_template [template_path: string, theme_data: record] {
  let template_content = (open $template_path | into string | collect)
  let output_path = (get_output_path $template_path)
  
  print $"Processing template: ($template_path) -> ($output_path)"
  
  # Replace all placeholders in the template
  let processed_content = (
    $theme_data
    | columns
    | reduce --fold $template_content {|key, acc|
        let placeholder = "{{" + $key + "}}"
        let val = ($theme_data | get $key | into string)
        $acc | str replace --all $placeholder $val
      }
  )
  
  # Save the processed content
  $processed_content | save -f $output_path
  
  print $"Template processed successfully: ($output_path)"
}

# Process all templates
def process_all_templates [theme_data: record] {
  ls ./templates
  | where type == file
  | each {|entry|
      try {
        process_template $entry.name $theme_data
      } catch {|err|
        print $"Error processing template ($entry.name): ($err)"
      }
    }
}

# Generate individual output for debugging purposes
let wezterm_output = (
  $theme
  | columns
  | reduce --fold (open ./templates/wezterm.template.lua | into string | collect) {|key, acc|
      let placeholder = "{{" + $key + "}}"
      let val = ($theme | get $key | into string)
      $acc | str replace --all $placeholder $val
    }
)

# Save the wezterm output directly for backward compatibility
$wezterm_output | save -f ./colors.lua
print "Generated colors.lua in project root for backward compatibility"

# Process all templates
print "Processing all templates..."
process_all_templates $theme

