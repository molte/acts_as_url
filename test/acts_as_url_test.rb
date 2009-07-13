require 'test_helper'

class ActsAsUrlTest < Test::Unit::TestCase # ActiveSupport::TestCase
  load_schema
  
  class Item < ActiveRecord::Base
    acts_as_url :website, :repository => 'git'
  end
  
  def test_schema_has_loaded_correctly
    assert_not_nil Item.all
  end
  
  # Validation tests
  def test_validation_when_no_protocol_or_path
    @item.website = 'example.com'
    assert @item.valid?
  end
  
  def test_validation_when_no protocol_but_path
    @item.website = 'example.info/directory/page.html?query=true&still=true#hash'
    assert @item.valid?
  end
  
  def test_validation_when_protocol
    @item.website = 'https://example.com/'
    assert @item.valid?
  end
  
  def test_validation_when_subdomains
    @item.website = 'dk.subdomain.example.net'
    assert @item.valid?
  end
  
  def test_validation_when_port
    @item.website = 'http://example.com:8080/'
    assert @item.valid?
  end
  
  def test_validation_when_no_tld
    @item.website = 'example'
    assert @item.invalid?
  end
  
  def test_validation_when_wrong_protocol
    @item.website = 'ftp://example.com/'
    assert @item.invalid?
  end
  
  def test_validation_when_blank
    @item.website = ''
    assert @item.valid?
  end
  
  # Convertion tests
  def test_default_convertion
    @item.website = 'example.com'
    assert_equal 'example.com', @item.website
    
    @item.save
    assert_equal 'http://example.com/', @item.website
  end
  
  def test_custom_convertion
    @item.repository = 'github.com/molte/acts_as_url.git'
    @item.save
    assert_equal 'git://github.com/molte/acts_as_url.git', @item.repository
  end
  
  def test_convertion_when_protocol_provided
    @item.website = 'https://eksempel.dk'
    @item.save
    assert_equal 'https://eksempel.dk/', @item.website
  end
  
  def test_convertion_when_blank
    @item.website = ''
    @item.save
    assert @item.website.blank?
  end
  
  def setup
    @item = Item.new
  end
  
end
