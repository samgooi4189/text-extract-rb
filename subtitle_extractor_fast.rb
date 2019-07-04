require 'pathname'
require 'open3'
require 'vips'

SRC_DIR = './source'.freeze
TMP_DIR = './output'.freeze

class TextReader
  def initialize(input_path, output_path)
    @input_path  = input_path
    @output_path = output_path
  end

  def read
    # prepare the image
    #
    # Read the image as grayscale
    img    = Vips::Image.new_from_file(@input_path, access: :sequential).colourspace('b-w')
    #
    # convert the image to binary; into black and white
    img_bw = img > 237  # that's the threshold
    img_bw.write_to_file(@output_path)

    # read the text and return it
    text, _,  _ =
      Open3.capture3("tesseract #{@output_path} stdout -l eng --oem 0 --psm 3")
    text.strip
  end
end

text_found = 0
text_not_found = 0

Dir.mkdir TMP_DIR unless File.exists?(TMP_DIR)

Pathname.new(SRC_DIR).children.each do |f|
	extracted_text = TextReader.new(f.realpath.to_s,
                            "#{TMP_DIR}/#{f.basename}")
    .read
    .downcase
    #.gsub(/[[:punct:]]/, ' ')
    #.split
    #.join('-')

  if !extracted_text.empty?
    text_found += 1
  else
    text_not_found += 1
  end

  puts extracted_text
end

puts "*" * 50
puts "#{text_found} files have text extracted vs. #{text_not_found} files do not have text recognized."
