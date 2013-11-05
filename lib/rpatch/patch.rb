require 'rpatch/error'
require 'rpatch/entry'

  class Patch
    class <<self
      def apply(path, patches, patch_level)
        unless File.exist? path
          raise FileNotExistError, "File or directory \"#{path}\" does not exist"
        end
        patch_status = true
        patches.each do |patch_file|
          if patch_file.is_a? IO or patch_file.is_a? StringIO
            apply_one(path, patch_file, patch_level) || patch_status = false
          elsif File.file? patch_file
            apply_one(path, patch_file, patch_level) || patch_status = false
          elsif File.directory? patch_file
            apply_quilt(path, patch_file, patch_level) || patch_status = false
          else
            raise FileNotExistError, "Can not find patch file: #{patch_file}"
          end
        end
        patch_status
      rescue Exception => e
        STDERR.puts "Error: #{e.message}"
        patch_status = false
      end
    end

    class <<self
      def apply_one(path, patch_file, patch_level)
        patch = Patch.new(patch_file, patch_level)
        patch.apply_to(path)
      end

      def apply_quilt(path, quilt_dir, patch_level)
        patch_status = true
        if File.exist?("#{quilt_dir}/series")
          File.open("#{quilt_dir}/series") do |io|
            io.readlines.each do |line|
              line.strip!
              filename = line
              level = patch_level
              if line =~ /^(.*?)[\s]+-p([0-9]*)$/
                filename = $1
                level = $2
              end
              unless filename.start_with? '#'
                apply_one(path, filename, level) || patch_status = false
              end
            end
          end
        else
          raise FileNotExistError, "Can not find (quilt) patchs in dir: #{quilt_dir}"
        end
        patch_status
      end
    end

            i += 1