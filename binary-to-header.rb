# Converts a binary file to an unsigned char array in a C header

usage_string = "usage: binary-to-header.rb <binary file path> <array name> <header output path>"

if ARGV.length < 3
    throw "Too few arguments to script (#{usage_string})"
elsif ARGV.length > 3
    throw "Too many arguments to script (#{usage_string})"
end

binary_file_path = ARGV[0]
array_name = ARGV[1]
header_output_path = ARGV[2]

bytes = IO.binread(binary_file_path)
          .unpack('C*')
          .join(",")

File.open(header_output_path, "w") do |output|
    output << <<~HEREDOC
    /* (Auto-generated binary data file). */
    #pragma once

    static const unsigned char #{array_name}[] = {
        #{bytes},0
    };

    static const unsigned int #{array_name}_size = #{bytes.length};
    HEREDOC
end
