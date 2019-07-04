require 'pathname'
require 'open3'
require 'mini_magick'

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
    # Read and write the image as grayscale
    img = MiniMagick::Image.open(@input_path)
    img.colorspace('Gray')
    img.write(@output_path)
    #
    # negate the image into black and white
    MiniMagick::Tool::Convert.new do |magick|
      magick << @output_path
      magick.negate
      magick.threshold("007%")    # I couldn't prevent myself
      magick.negate
      magick << @output_path
    end

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
  extracted_text = TextReader.new(f.realpath,
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
