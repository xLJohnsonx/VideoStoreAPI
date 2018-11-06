require "test_helper"

describe MoviesController do
  it "should get show" do
    get movies_show_url
    value(response).must_be :success?
  end

  it "should get index" do
    get movies_index_url
    value(response).must_be :success?
  end

  it "should get create" do
    get movies_create_url
    value(response).must_be :success?
  end

  it "should get update" do
    get movies_update_url
    value(response).must_be :success?
  end
  describe 'API' do
    describe 'get' do
      it "is working route that returns json" do
        # Act
        get movies_path
        # Assert
        expect(response.header['Content-Type']).must_include 'json'
        must_respond_with :success
      end

      it 'returns an array' do
        get movies_path

        body = JSON.parse(response.body)

        expect(body).must_be_kind_of Array
      end

      describe 'show' do
        it 'returns an individual response' do
          get movies_path/(movies(:movie_out).id)
          must_responsd_with :success

          # body = JSON.parse(response.body)
          # expect(body.length).must_equal 1
          # expect(body.)
        end

        it 'return a 404 if movie DNE' do
          get movies_path/45
          must_respond_with :not_found
        end
      end

      describe 'create' do
        it 'has a properly defined route' do

        end

        it 'can create a new movie in db with valid data' do

        end

        it 'will not change db if a movie is created w/ garbage data' do

        end
      end

      end



  end

end
