require "yaml"
require "colorize"

input_file = "helm_template.yaml"
input_dir = ENV["CI_PROJECT_DIR"] ||= "/tmp/helm"
input_path = "#{input_dir}/#{input_file}"
conf_files = [] of File
snippet = ""

nginx_conf = <<-NGINX
events {}
error_log /tmp/error.log;
pid /tmp/nginx.pid;
http {
  access_log /tmp/access.log;
  server { #{snippet} }
}
NGINX

unless File.exists?(input_path)
  puts "Rendered template not found: #{input_path.colorize(:red)}"
  exit(1)
end

parsed_yaml = YAML.parse_all(File.read(input_path))

parsed_yaml.each do |yaml|
  if yaml["kind"] == "Ingress"
    begin
      snippet = yaml["metadata"]["annotations"]["nginx.ingress.kubernetes.io/server-snippet"].to_s
      ingress_name = yaml["metadata"]["name"].to_s

      tempconf = File.tempfile("nginx", ".conf") do |file|
        file.print(nginx_conf)
      end

      conf_files << tempconf
      puts "Snippet for ingress: #{ingress_name.colorize(:yellow)}"
      puts "---"
      puts snippet
      puts "..."
    rescue
      puts "No server-snippet in ingress #{ingress_name.colorize(:yellow)}.\n\n"
    end
  end
end

conf_files.each do |conf|
  stdout = IO::Memory.new
  stderr = IO::Memory.new
  ps = Process.new("nginx", ["-t", "-c", conf.path], output: stdout, error: stderr)

  unless ps.wait.success?
    puts stdout.to_s.colorize(:red)
    puts stderr.to_s.colorize(:red)
    exit(1)
  end
end

puts "Configuration check successful.".colorize(:green)
