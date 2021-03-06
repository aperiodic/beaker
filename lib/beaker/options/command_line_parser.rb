module Beaker
  module Options
    #An object that parses arguments in the format ['--option', 'value', '--option2', 'value2', '--switch']
    class CommandLineParser

      # @example Create a CommanLineParser
      #   a = CommandLineParser.new     
      #    
      # @note All of Beaker's supported command line options are defined here
      def initialize
        @cmd_options = Beaker::Options::OptionsHash.new

        @optparse = OptionParser.new do|opts|
          # Set a banner
          opts.banner = "Usage: #{File.basename($0)} [options...]"

          opts.on '-h', '--hosts FILE',
                  'Use host configuration FILE',
                  '(default sample.cfg)'  do |file|
            @cmd_options[:hosts_file] = file
          end

          opts.on '-o', '--options-file FILE',
                  'Read options from FILE',
                  'This should evaluate to a ruby hash.',
                  'CLI optons are given precedence.' do |file|
            @cmd_options[:options_file] =  file
          end

          opts.on '--type TYPE',
                  'one of git or pe', 
                  'used to determine underlying path structure of puppet install',
                  '(default pe)' do |type|
            @cmd_options[:type] = type
          end

          opts.on '--helper PATH/TO/SCRIPT',
                  'Ruby file evaluated prior to tests',
                  '(a la spec_helper)' do |script|
            @cmd_options[:helper] = script
          end

          opts.on  '--load-path /PATH/TO/DIR,/ADDITIONAL/DIR/PATHS',
                   'Add paths to LOAD_PATH'  do |value|
            @cmd_options[:load_path] = value
          end

          opts.on  '-t', '--tests /PATH/TO/DIR,/ADDITIONA/DIR/PATHS,/PATH/TO/FILE.rb',
                   'Execute tests from paths and files' do |value|
            @cmd_options[:tests] = value
          end

          opts.on '--pre-suite /PRE-SUITE/DIR/PATH,/ADDITIONAL/DIR/PATHS,/PATH/TO/FILE.rb',
                  'Path to project specific steps to be run BEFORE testing' do |value|
            @cmd_options[:pre_suite] = value
          end

          opts.on '--post-suite /POST-SUITE/DIR/PATH,/OPTIONAL/ADDITONAL/DIR/PATHS,/PATH/TO/FILE.rb',
                  'Path to project specific steps to be run AFTER testing' do |value|
            @cmd_options[:post_suite] = value
          end

          opts.on '--[no-]provision',
                  'Do not provision vm images before testing',
                  '(default: true)' do |bool|
            @cmd_options[:provision] = bool
          end

          opts.on '--[no-]preserve-hosts',
                  'Preserve cloud instances' do |value|
            @cmd_options[:preserve_hosts] = value
          end

          opts.on '--root-keys',
                  'Install puppetlabs pubkeys for superuser',
                  '(default: false)' do |bool|
            @cmd_options[:root_keys] = bool
          end

          opts.on '--keyfile /PATH/TO/SSH/KEY',
                  'Specify alternate SSH key',
                  '(default: ~/.ssh/id_rsa)' do |key|
            @cmd_options[:keyfile] = key
          end

          opts.on '--timeout TIMEOUT',
                  '(vCloud only) Specify a provisioning timeout (in seconds)',
                  '(default: 300)' do |value|
            @cmd_options[:timeout] = value
          end

          opts.on '-i URI', '--install URI',
                  'Install a project repo/app on the SUTs', 
                  'Provide full git URI or use short form KEYWORD/name',
                  'supported keywords: PUPPET, FACTER, HIERA, HIERA-PUPPET' do |value|
            @cmd_options[:install] = value
          end

          opts.on('-m', '--modules URI', 'Select puppet module git install URI') do |value|
            @cmd_options[:modules] = value
          end

          opts.on '-q', '--[no-]quiet',
                  'Do not log output to STDOUT',
                  '(default: false)' do |bool|
            @cmd_options[:quiet] = bool
          end

          opts.on '-x', '--[no-]xml',
                  'Emit JUnit XML reports on tests',
                  '(default: false)' do |bool|
            @cmd_options[:xml] = bool
          end

          opts.on '--[no-]color',
                  'Do not display color in log output',
                  '(default: true)' do |bool|
            @cmd_options[:color] = bool
          end

          opts.on '--log-level LEVEL',
                  'Log level',
                  'Supported LEVEL keywords:',
                  'debug   : all messages, plus full stack trace of errors',
                  'verbose : all messages',
                  'info    : info messages, notifications and warnings',
                  'notify  : notifications and warnings',
                  'warn    : warnings only',
                  '(default: info)' do |val|
            @cmd_options[:log_level] = val
          end

          opts.on '--[no-]debug',
                  'DEPRECATED, use --log-level' do |bool|
            @cmd_options[:log_level] =  bool ? 'debug' : 'info'
          end

          opts.on  '-d', '--[no-]dry-run',
                   'Report what would happen on targets',
                   '(default: false)' do |bool|
            @cmd_options[:dry_run] = bool
            $dry_run = bool
          end

          opts.on '--fail-mode [MODE]',
                  'How should the harness react to errors/failures',
                  'Possible values:',
                  'fast (skip all subsequent tests, cleanup, exit)',
                  'stop (skip all subsequent tests, do no cleanup, exit immediately)'  do |mode|
            @cmd_options[:fail_mode] = mode
          end

          opts.on '--[no-]ntp',
                  'Sync time on SUTs before testing',
                  '(default: false)' do |bool|
            @cmd_options[:timesync] = bool
          end

          opts.on '--repo-proxy',
                  'Proxy packaging repositories on ubuntu, debian and solaris-11',
                  '(default: false)' do
            @cmd_options[:repo_proxy] = true
          end

          opts.on '--add-el-extras',
                  'Add Extra Packages for Enterprise Linux (EPEL) repository to el-* hosts',
                  '(default: false)' do
            @cmd_options[:add_el_extras] = true
          end

          opts.on('--version', 'Report currently running version of beaker' ) do 
            @cmd_options[:version] = true
          end

          opts.on '-c', '--config FILE',
                  'DEPRECATED use --hosts' do |file|
            @cmd_options[:hosts_file] = file
          end

          opts.on('--help', 'Display this screen' ) do 
            @cmd_options[:help] = true
          end
        end

      end

      # Parse an array of arguments into a Hash of options
      # @param [Array] args The array of arguments to consume
      #
      # @example
      #   args = ['--option', 'value', '--option2', 'value2', '--switch']
      #   parser = CommandLineParser.new
      #   parser.parse!(args) == {:option => 'value, :options2 => value, :switch => true}
      #
      # @return [Hash] Return the Hash of options
      def parse!( args = ARGV )
        @optparse.parse!(args)
        @cmd_options
      end

      # Generate a string representing the supported arguments
      #
      # @example 
      #    parser = CommandLineParser.new 
      #    parser.usage = "Options:  ..." 
      #
      # @return [String] Return a string representing the available arguments
      def usage
        @optparse.help
      end

    end
  end
end
