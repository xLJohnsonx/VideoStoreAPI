require "test_helper"

describe Movie do
  describe 'Validations' do
    let (:new_movie) { Movie.new(title: "valid movie",
                             overview: "overview",
                             release_date: Date.current,
                             inventory: 99)
                 }

    it "a movie can be created with all required fields present" do
      new_movie.save
      new_movie.valid?.must_equal true
    end

    it "a movie cannot be created if any required field is not present" do
      fields = [:title, :overview, :release_date, :inventory]
      setters = [:title=, :overview=, :release_date=, :inventory=]
      setters.each_with_index do |setter, index|
        new_movie.send(setter, nil)
        new_movie.valid?.must_equal false
        new_movie.errors.messages.must_include fields[index]
      end
    end
  end

  describe 'relationships' do
    let(:mov) { movies(:movie_out3) }

    it 'has many rentals' do
      rents = mov.rentals

      expect(rents.length).must_be :>, 1
      rents.each do |r|
        expect(r).must_be_instance_of Rental
      end
    end

    it 'has many customers through rental' do
      custs = mov.customers
      expect(custs.length).must_be :>, 1
      custs.each do |c|
        expect(c).must_be_instance_of Customer
      end
    end
  end
end
