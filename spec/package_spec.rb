require_relative 'spec_helper'

require_relative '../lib/office/package'
require_relative '../lib/office/word'
require_relative '../lib/office/excel'

require_relative 'modules.rb'
require_relative 'package_debug.rb'

describe Office::Package do
  describe '#add_image_part' do
    include Reload
    using PackageDebug

    let :image do Magick::ImageList.new ImageFiles::TEST_IMAGE end
    let :word do Office::WordDocument.new DocFiles::IMAGE_REPLACEMENT_TEST end
    let :book do Office::ExcelWorkbook.new BookFiles::IMAGE_TEST end
    let :simple do Office::ExcelWorkbook.new BookFiles::SIMPLE_TEST end

    def main_part document
      candidates =
      case document
      when Office::WordDocument; document.parts.filter{|name, _part| name =~ /word.document/}
      when Office::ExcelWorkbook; document.parts.filter{|name, _part| name =~ /xl.workbook/}
      end

      raise "must be one" unless candidates.size == 1
      # document.parts is a hash, so fetch the value from the first pair
      _name, part = candidates.first
      part
    end

    docs = {
      word: Office::WordDocument.new(DocFiles::IMAGE_REPLACEMENT_TEST),
      book: Office::ExcelWorkbook.new(BookFiles::IMAGE_TEST),
      simple: Office::ExcelWorkbook.new(BookFiles::SIMPLE_TEST),
    }

    docs.each do |name, doc|
      describe name do
        # TODO handle the functionality of make_sure_section_has_relationships!
        # TODO start sheet must contain absolutely no images or rels
        it 'adds rels/.rels or whatever its called'

        # Types/Override PartName="/xl/media/image1.jpeg" ContentType="image/jpeg"/>
        it 'add overrides'

        # TODO this belongs in excel_spec or similar
        # in the xml, we have
        #  xl/worksheets/_rels/sheet1.xml.rels -> xl/drawings/_rels/drawing1.xml.rels -> Target="../media/image1.jpeg"

        it 'adds rels for image' do
          # here it doesn't really matter what part the image is added to, as long as it shows up in the saved zip/xml
          part = main_part(doc)
          rel_id, image_part = doc.add_image_part image, part

          # now there should be a rel from main_part(doc) to the image part
          # TODO test rel_part
          rel_part = part.get_relationship_by_id rel_id
          image_rel_path = %<//*:Relationship[@Id = '#{rel_id}'][@Target = '#{rel_part.target_name}']>

          # zip file does not yet contain the new image
          doc.ztree.nxpath(image_rel_path).size.should == 0
          # in-memory structure contains the new image
          doc.xtree.nxpath(image_rel_path).size.should == 1

          target_part = reload doc do |saved|
            # fetch part by relId and verify
            source_part = main_part(saved)
            rel = source_part.get_relationship_by_id rel_id
            rel.target_part
          end

          # outside block so we know the block actually executed
          target_part.name.should == image_part.name
        end

        it 'adds media file for image' do
          # it doesn't really matter what part the image is added to, as long as it shows up in the saved zip/xml
          part = main_part(doc)
          rel_id, image_part = doc.add_image_part image, part

          saved_image_part = reload_document doc do |saved|
            saved.parts[image_part.name]
          end

          # outside block so we know the block actually executed
          saved_image_part.should be_a(Office::ImagePart)
        end

        it 'adds image part' do
          # it doesn't really matter what part the image is added to, as long as it shows up in the saved zip/xml
          part = main_part(doc)
          rel_id, image_part = doc.add_image_part image, part

          image_part = reload_document doc do |saved|
            # fetch part by relId and verify
            source_part = main_part(saved)
            rel = source_part.get_relationship_by_id rel_id
            rel.target_part.name.should == image_part.name
            rel.target_part
          end

          # outside block so we know the block actually executed
          image_part.should be_a(Office::ImagePart)
        end
      end
    end
  end
end