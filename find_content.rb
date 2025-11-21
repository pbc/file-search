require "io/console"

def find_content(search_term, file_path, case_insensitive_sorted_file=false)
  debug_mode = ENV["DEBUG"] == "true"
  
  file_size = File.size(file_path)
  
  window_start_position = 0
  window_end_position = file_size
  
  previous_window = [0,0]
  
  current_closest_match = ""
  
  if File.directory? file_path
    raise StandardError.new("Provided file path needs to point to a file, not a directory.")
  end
  
  require_precise_read = false
  
  open file_path, "r" do |file|
    
    while true
      
      current_window = [window_start_position, window_end_position]
      
      puts [window_start_position, window_end_position].inspect if debug_mode
      
      if window_start_position >= window_end_position
        puts "window_start_position >= window_end_position : #{[window_start_position, window_end_position].inspect}" if debug_mode
        # there are no more locations to check
        break
      end
      
      current_position = ((window_start_position + window_end_position) / 2.0).round(0).to_i
      
      puts "current_position: #{current_position}" if debug_mode
      
      file.pos = current_position
      
      if file.pos >= file_size
        break
      end
      
      if previous_window == current_window || require_precise_read
        
        while true
          
          file.pos = file.pos - 2
          
          if file.pos <= 0
            file.pos = 0
            # we've reach the start of the file, which can be considered the correct start of line we're looking for
            break
          end
          
          potential_line_feed = file.read(1)
          
          if potential_line_feed == "\n"
            # we've reach previous line feed and read it, which can be considered the correct start of line we're looking for
            break
          end
          
          if file.pos >= file_size
            file.pos = 0
            # we've reach the end of the file so the file is either empty or has just a single line feed character
            break
          end
        end
      else
        # read and discard partial line
        file.readline
        
        if file.pos >= file_size
          # we've reach the end of file after partial read, so need to find the start of line of the partial instead
          puts "partial read till the end of file detected. replaying to set the read position at the start of line of the partial" if debug_mode
          require_precise_read = true
          next
        end
      end
      
      line_start_position = file.pos
      current_line = file.readline
      line_end_position = line_start_position + current_line.length - 1
      
      current_line_trimmed = current_line.strip
      current_line_trimmed = current_line_trimmed.downcase if case_insensitive_sorted_file
      
      previous_window = [window_start_position, window_end_position]
      
      puts "current_line_trimmed: #{current_line_trimmed}" if debug_mode
      
      if current_line_trimmed == search_term
        current_closest_match = current_line
        break
      elsif current_line_trimmed < search_term
        # move forward to the next half
        window_start_position = line_end_position + 1
      elsif current_line_trimmed > search_term
        # move backward to the previous half
        window_end_position = line_start_position - 1
        current_closest_match = current_line
      else
        raise StandardError.new("Incorrect string comparison case detected.")
      end
    end
    
    current_closest_match
  end
end

search_term_input = ARGV[0]
file_path_input = ARGV[1]

puts find_content(search_term_input, file_path_input)

