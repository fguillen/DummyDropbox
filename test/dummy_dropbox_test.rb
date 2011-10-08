require 'test/unit'
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
    assert_raise(Dropbox::UnsuccessfulResponseError) {@session.download( '/filex.txt')}
  end
  
  def test_metadata
    assert( !@session.metadata( '/file1.txt' ).directory? )
    assert( @session.metadata( '/folder1' ).directory? )
  end
  
  def test_list
    assert_equal(['/file1.txt', '/folder1'].sort, @session.list('').map{ |e| e.path }.sort)
    assert_equal(['folder1/file2.txt', 'folder1/file3.txt'].sort, @session.list('folder1').map{ |e| e.path }.sort )
  end

  def test_delete
    FileUtils.mkdir_p( "#{DummyDropbox.root_path}/tmp_folder" )
    3.times { |i| FileUtils.touch( "#{DummyDropbox.root_path}/tmp_folder/#{i}.txt" ) }

    assert( File.exists?( "#{DummyDropbox.root_path}/tmp_folder" ) )    
    assert( File.exists?( "#{DummyDropbox.root_path}/tmp_folder/0.txt" ) )
    
    metadata = @session.delete '/tmp_folder/0.txt'
    assert( !File.exists?( "#{DummyDropbox.root_path}/tmp_folder/0.txt" ) )

    metadata = @session.delete '/tmp_folder'
    assert( !File.exists?( "#{DummyDropbox.root_path}/tmp_folder" ) )
  end

  def test_rename
    FileUtils.mkdir_p( "#{DummyDropbox.root_path}/tmp_folder" )
    assert( File.exists?( "#{DummyDropbox.root_path}/tmp_folder" ) )

    @session.rename '/tmp_folder', 'temp_folder'
    assert !@session.list('/').detect {|e| e.path == '/tmp_folder'}
    assert @session.list('/').detect {|e| e.path == '/temp_folder'}
    
    FileUtils.rmdir( "#{DummyDropbox.root_path}/temp_folder" )
  end

  def test_move
    FileUtils.mkdir_p( "#{DummyDropbox.root_path}/tmp_folder" )

    @session.move 'file1.txt', 'tmp_folder/file1.txt'
    assert !@session.list('/').detect {|e| e.path == '/file1.txt'}
    assert @session.list('/tmp_folder').detect {|e| e.path == '/tmp_folder/file1.txt'}
    
    @session.move '/tmp_folder/file1.txt', '/file1.txt'

    FileUtils.rmdir( "#{DummyDropbox.root_path}/tmp_folder" )
  end
  
  def test_create_folder
    FileUtils.rm_r( "#{DummyDropbox.root_path}/tmp_folder" )  if File.exists?( "#{DummyDropbox.root_path}/tmp_folder" )
    metadata = @session.create_folder '/tmp_folder'
    assert( File.directory?( "#{DummyDropbox.root_path}/tmp_folder" ) )
    assert( metadata.directory? )
    assert( metadata.is_dir )
    assert_equal metadata.revision, 32
    assert_raise(Dropbox::FileExistsError) {@session.create_folder('/tmp_folder')}
    FileUtils.rm_r( "#{DummyDropbox.root_path}/tmp_folder" )
  end
  
  def test_upload
    FileUtils.rm_r( "#{DummyDropbox.root_path}/file.txt" )  if File.exists?( "#{DummyDropbox.root_path}/file.txt" )
    metadata = @session.upload( "#{File.dirname(__FILE__)}/fixtures/file.txt", '/' )
    assert_equal( 
      File.read( "#{File.dirname(__FILE__)}/fixtures/file.txt" ),
      File.read( "#{DummyDropbox.root_path}/file.txt" )
    )
    assert( !metadata.directory? )
    assert( !metadata.is_dir )
    assert_equal metadata.mime_type, 'image/jpeg'
    assert_equal metadata.revision, 79
    FileUtils.rm_r( "#{DummyDropbox.root_path}/file.txt" )
    
    metadata = @session.upload( StringIO.new("stuff"), '/', :as => "stringio.txt")
    assert( File.exists?( "#{DummyDropbox.root_path}/#{metadata.path}" ) )
    FileUtils.rm_r( "#{DummyDropbox.root_path}/stringio.txt" ) if File.exists?( "#{DummyDropbox.root_path}/stringio.txt" )
  end
end