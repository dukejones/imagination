require 'spec_helper'
require 'imagination'
require 'mini_magick'
require 'byebug'

class Image
  include Imagination::ImageFileManager
  attr_accessor :image_path

  def created_at
    Time.now
  end

  def magick_image(profile_name=nil, options={})
    MiniMagick::Image.open(file_path(profile_name, options))
  end
end

describe Imagination::ImageFileManager do
  before do
    setup_test_public_dir
    @test_file = File.join(TEST_FILE_PATH, '1f004.png')
  end
  after do
    empty_test_public_dir
  end

  context "#intake_file" do
    it "copies the file we give it into the image uploads directory" do
      image = Image.new
      upload_path = image.generate_relative_upload_path(@test_file)
      image.intake_file @test_file
      expect( File.file?(File.join(TEST_PUBLIC_DIR, Image::UPLOAD_DIR, upload_path)) ).to eq(true)
    end

    it "avoids name collisions on files" do
      image = Image.new

      # copy file of same name to force a collision
      first_upload_path = image.generate_relative_upload_path(@test_file)
      upload_dir = File.join TEST_PUBLIC_DIR, Image::UPLOAD_DIR, File.dirname(first_upload_path)
      FileUtils.mkdir_p(upload_dir)
      FileUtils.cp(@test_file, upload_dir)

      # intake the file of same name
      # second_upload_path = image.generate_full_upload_path(@test_file)
      image_path = image.intake_file(@test_file)
      # test that file name has an appended '-001'
      expect( File.basename(image_path) ).to match(/\-001\.png/)
    end

    it "denies a non-image" do
      @test_file = File.join(TEST_FILE_PATH, 'test.pdf')
      image = Image.new
      expect{image.intake_file(@test_file)}.to raise_error ImageException
    end
  end

  context "#file_path" do
    it "generates the path to the original file" do
      image = Image.new
      image_path = image.intake_file(@test_file)

      expect( image.file_path ).to eq(File.join(TEST_PUBLIC_DIR, Image::UPLOAD_DIR, image.image_path))
    end

    it "generates the path to a resized profile" do
      image = Image.new
      image.intake_file(@test_file)

      expect( image.file_path(:header) ).to include(Image::CACHE_DIR)
      expect( image.file_path(:header) ).to match(/\-header\.png/)
    end
  end

  context "#save_profile" do
    it "creates a file in the proper directory" do
      image = Image.new
      image.intake_file(@test_file)
      image.save_profile(image.magick_image, :test_profile)

      expect( File.file?(image.file_path(:test_profile)) ).to eq(true)
    end
  end
end
