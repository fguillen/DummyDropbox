require 'rubygems'
require 'test/unit'
require 'ostruct'
require 'dropbox'
require "#{File.dirname(__FILE__)}/../lib/dummy_dropbox.rb"

class DummyDropboxTest < Test::Unit::TestCase
  def setup
    @session = Dropbox::Session.new('key', 'secret')
  end
   
  def test_session
    assert_equal( "#<Dropbox::Session dummy key consumer (authorized)>", @session.inspect )
  end
  
  def test_download
    assert_equal( "File 1", @session.download( '/file1.txt' ) )
  end
  
  def test_metadata
    assert( !@session.metadata( '/file1.txt' ).directory? )
    assert( @session.metadata( '/folder1' ).directory? )
  end
  
  def test_list
    assert_equal(['/file1.txt', '/folder1'], @session.list('').map{ |e| e.path } )
    assert_equal(['folder1/file2.txt', 'folder1/file3.txt'], @session.list('folder1').map{ |e| e.path } )
  end
end