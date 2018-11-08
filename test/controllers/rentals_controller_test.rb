require "test_helper"
require 'date'

describe RentalsController do
  let(:rental) {
   { customer_id: 859843310,
     movie_id: 400453147
   }
  }

  it 'can checkout a movie' do
   # POST /rentals/check_out
   fields = %w(id movie_id customer_id due_date checkout_date checkin_date).sort
   movie_inv_avail_start = Movie.find(400453147).inventory_available
   expect do
     post check_out_path, params: rental, as: :json
   end.must_change 'Rental.count', 1

   movie_inv_avail_end = Movie.find(400453147).inventory_available
   value(response).must_be :successful?

   expect(response.header['Content-Type']).must_include 'json'
   body = JSON.parse(response.body)

   expect(body.keys.sort).must_equal fields
   expect(body["checkout_date"]).must_equal Date.today.to_s
   expect(body["checkin_date"]).must_be_nil
   expect(body["due_date"]).must_equal (Date.today + 7).to_s
   expect(movie_inv_avail_end).must_equal movie_inv_avail_start - 1
  end

  it 'can checkin a movie' do
   # post '/rentals/check_in'
   fields = %w(id movie_id customer_id due_date checkout_date checkin_date).sort
   post check_out_path, params: rental
   movie_inv_avail_start = Movie.find(400453147).inventory_available

   expect do
     post check_in_path, params: rental, as: :json
   end.wont_change 'Rental.count'

   movie_inv_avail_end = Movie.find(400453147).inventory_available
   value(response).must_be :successful?

   expect(response.header['Content-Type']).must_include 'json'
   body = JSON.parse(response.body)

   expect(body.keys.sort).must_equal fields
   expect(body["checkin_date"]).must_equal Date.today.to_s
   expect(movie_inv_avail_end).must_equal movie_inv_avail_start + 1
  end

  describe 'SJL: mimicking the postman wave3 smoke test' do
    let (:customer) { customers(:customer_out)}
    let (:movie) { movies(:movie_in)}
    let(:new_rental_params) {
     { customer_id: customer.id,
       movie_id: movie.id
     }
    }
    it 'checking OUT a movie increases customer mcoc count by one' do

      # START
      get customers_path, as: :json
      body = JSON.parse(response.body) # array of all customers
      body = body.select {|cust| cust["id"] == customer.id} # array of a single customer hash
      mcoc_start = body[0]["movies_checked_out_count"]
      expect(mcoc_start).must_equal 3 # just to be sure of our fixtures

      # CHECKOUT
      post check_out_path, params: new_rental_params, as: :json
      value(response).must_be :successful?

      # END
      get customers_path, as: :json
      body2 = JSON.parse(response.body) # array of all customers
      body2 = body2.select {|cust| cust["id"] == customer.id} # array of a single customer hash
      mcoc_end = body2[0]["movies_checked_out_count"]
      expect(mcoc_end).must_equal 4 # FAIL: expect 4, actual 0
    end

    it 'checking IN a movie decreases customer mcoc count by one' do
      # ZERO
      get customers_path, as: :json
      value(response).must_be :successful?
      body = JSON.parse(response.body) # array of all customers
      body = body.select {|cust| cust["id"] == customer.id} # array of a single customer hash
      mcoc_zero = body[0]["movies_checked_out_count"]
      expect(mcoc_zero).must_equal 3 # from fixtures
      expect(Rental.count).must_equal 4

      # CHECK OUT
      post check_out_path, params: new_rental_params, as: :json
      value(response).must_be :successful?
      expect(Rental.count).must_equal 5

      # BEFORE
      get customers_path, as: :json
      value(response).must_be :successful?
      body2 = JSON.parse(response.body) # array of all customers
      body2 = body2.select {|cust| cust["id"] == customer.id}
      mcoc_before = body2[0]["movies_checked_out_count"]
      expect(mcoc_before).must_equal 4 # mcoc_zero + 1

      # CHECK IN
      post check_in_path, params: new_rental_params, as: :json
      value(response).must_be :successful?
      expect(Rental.count).must_equal 5

      # AFTER
      get customers_path, as: :json
      value(response).must_be :successful?
      body3 = JSON.parse(response.body) # array of all customers
      body3 = body3.select {|cust| cust["id"] == customer.id}
      mcoc_end = body3[0]["movies_checked_out_count"]
      expect(mcoc_end).must_equal 3 #mcoc_zero


      ################################################
      # TWO
      ################################################

      # ZERO
      get customers_path, as: :json
      value(response).must_be :successful?
      body = JSON.parse(response.body) # array of all customers
      body = body.select {|cust| cust["id"] == customer.id} # array of a single customer hash
      mcoc_zero = body[0]["movies_checked_out_count"]
      expect(mcoc_zero).must_equal 3 # from fixtures
      expect(Rental.count).must_equal 5

      # CHECK OUT
      post check_out_path, params: new_rental_params, as: :json
      value(response).must_be :successful?
      expect(Rental.count).must_equal 6

      # BEFORE
      get customers_path, as: :json
      value(response).must_be :successful?
      body2 = JSON.parse(response.body) # array of all customers
      body2 = body2.select {|cust| cust["id"] == customer.id}
      mcoc_before = body2[0]["movies_checked_out_count"]
      expect(mcoc_before).must_equal 4 # mcoc_zero + 1

      # CHECK IN
      post check_in_path, params: new_rental_params, as: :json
      value(response).must_be :successful?

      # AFTER
      get customers_path, as: :json
      value(response).must_be :successful?
      body3 = JSON.parse(response.body) # array of all customers
      body3 = body3.select {|cust| cust["id"] == customer.id}
      mcoc_end = body3[0]["movies_checked_out_count"]
      expect(Rental.count).must_equal 6
      expect(mcoc_end).must_equal 3 #mcoc_zero # FAIL: expect 3, actual 4
    end
  end

  describe 'errors' do
    let(:customer) { customers(:customer_out)}
    let(:movie) { movies(:movie_in)}
    let(:rental) {
      { customer_id: customer.id,
        movie_id: movie.id
      }
    }
    let(:rental_bad) {
      { customer_id: customer.id,
        movie_id: 1337
      }
    }

    it 'sends an error msg when all movies have been checked out' do
      # checkout a movie with inventory of 1 twice
      post check_out_path, params: rental, as: :json
      post check_out_path, params: rental, as: :json

      must_respond_with :bad_request

      body = JSON.parse(response.body)
      expect(body["ok"]).must_equal false
      expect(body["cause"]).must_equal "validation errors"
      # expect(body["errors"]["messages"]).must_include "all copies are currently checked out"
    end


    it 'sends a validation error when checkout data is garbage' do
      # check out with bad movie id
      post check_out_path params: rental_bad, as: :json
      must_respond_with :bad_request

      body = JSON.parse(response.body)
      expect(body["ok"]).must_equal false
      expect(body["cause"]).must_equal "validation errors"
      # expect(body["errors"]["messages"]).must_include "movie id not in database"

    end
  end
end
