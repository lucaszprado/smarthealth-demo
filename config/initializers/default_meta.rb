# Initialize default meta tags
# Must be defined as an environment variable
DEFAULT_META = YAML.load_file(Rails.root.join("config/meta.yml"))
# YAML.load_file loads the yml file and returns a hash
