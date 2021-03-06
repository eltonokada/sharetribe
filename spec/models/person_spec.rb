require 'spec_helper'

describe Person do
  
 
   before(:all) do
      #These will be created only once for the whole example group
      @test_person = FactoryGirl.build(:person)
    end
  

    it "should be valid" do
      @test_person.class.should == Person
      @test_person.should_not be_nil
      @test_person.should be_valid
    end

    it "should have an id other than 0" do
      @test_person.id.should_not == 0
      # "Test_person.id is 0, possible reason is INT type for id in test DB."
    end

    describe "#create" do
      it "should create a person in Sharetribe DB" do
        username = generate_random_username
        p = Person.create!({:username => username, 
          :password => "testi", 
          :email => "#{username}@example.com",
          "given_name" => "Tero",
          "family_name" => "Turari"})
        Person.find(p.id).should_not be_nil
        p.username.should == username
      end

      it "should not store anything to Sharetribe DB if creation failed for invalid data" do
        username = generate_random_username
        lambda {
          p = nil
          lambda {
            p = Person.create!({:username => username, 
              :password => "testi", 
              :emails => [Email.new(:address => "invalid-email")],
              "given_name" => "Tero",
              "family_name" => "Turari"})
          }.should raise_error(ActiveRecord::RecordInvalid)
          p.should be_nil
        }.should_not change{Person.count}
      end

      it "should not store person with invalid company_id" do
        username = generate_random_username
        lambda {
          p = nil
          lambda {
            p = Person.create!({:username => username,
              :company_id => "1234-5",
              :password => "testi", 
              :email => "info@company.com",
              "given_name" => "Tero",
              "family_name" => "Turari"})
          }.should raise_error(ActiveRecord::RecordInvalid)
          p.should be_nil
        }.should_not change{Person.count}
      end
    end

    describe "#update_attributes" do
      it "should update the attributes" do
        @test_person.update_attributes({'given_name' => "Totti", 
          'family_name' => "Tester", 
          'phone_number' => "050-55555555"})
        @test_person.family_name.should == "Tester"
        @test_person.phone_number.should == "050-55555555"
      end
    end

    describe "#create_listing" do
      it "creates a new listing with the submitted attributes" do
        listing = @test_person.create_listing :title => "Test", :share_type => "sell"
        listing.title.should == "Test"
        @test_person.listings.last.should == listing
      end
    end

    describe "name getters" do
      before(:each) do
        @test_person.update_attributes({'given_name' => "Ripa", 'family_name' => "Riuska"})
      end

      it "returns the name of the user" do
        @test_person.name.should_not be_blank
        @test_person.name.should == "Ripa R"
      end

      it "returns the given or the last name of the user" do
        @test_person.given_name.should == "Ripa"
        @test_person.family_name.should == "Riuska"
      end

      describe "#given_name" do

        it "should return the given name" do
          @test_person.given_name.should == "Ripa"
        end

        it "should return blank if given name is blank" do
          @test_person.update_attributes({'given_name' => "", 'family_name' => ""})
          @test_person.given_name.should == ""
        end

      end

      describe "#given_name_or_username" do

        it "should return the given name if it exists" do
          @test_person.given_name_or_username.should == "Ripa"
        end

        it "should return username if given name is blank" do
          @test_person.update_attributes({'given_name' => "", 'family_name' => ""})
          @test_person.given_name_or_username.should == @test_person.username
        end

      end
      
      describe "devise valid_password?" do
        it "Test that the hashing works. (makes more sense to test this if ASI digest is used)" do
          FactoryGirl.build(:person).valid_password?('testi').should be_true
          FactoryGirl.build(:person).valid_password?('something_else').should_not be_true
        end
      end

    end

    describe "#delete" do
      it "should delete also related conversations and testimonials" do
        conv = FactoryGirl.create(:conversation)
        conv.participants << @test_person
        conv_id = conv.id
        Conversation.find_by_id(conv_id).should_not be_nil
        @test_person.conversations.should include(conv)
        
        tes = FactoryGirl.create(:testimonial, :author => @test_person)
        tes_id = tes.id
        Testimonial.find_by_id(tes_id).should_not be_nil
        @test_person.authored_testimonials.should include(tes)
        
        @test_person.destroy
                
        # check that related stuff was removed too
        Conversation.find_by_id(conv_id).should be_nil
        Testimonial.find_by_id(tes_id).should be_nil
        
      end
    end
    
    describe "#latest_pending_email_address" do
      
      before (:each) do
        @p = FactoryGirl.create(:person)
      end
      
      it "should return nil if none pending" do
        @p.latest_pending_email_address().should be_nil
      end
      
      it "should return main email if that's pending" do
        @p.emails.each { |email| email.update_attribute(:confirmed_at, nil) }
        @p.latest_pending_email_address().should =~ /kassi_tester\d+@example.com/
      end
      
      it "should pick the right email to return" do
        c = FactoryGirl.create(:community, :allowed_emails => "@example.com, @ex.ample, @something.else")
        e = FactoryGirl.create(:email, :address => "jack@aalto.fi", :confirmed_at => nil, :person => @p)
        e2 = FactoryGirl.create(:email, :address => "jack@example.com", :confirmed_at => nil, :person => @p)
        # e3 = FactoryGirl.create(:email, :address => "jack@helsinki.fi", :confirmed_at => nil, :person => @p)

        @p.latest_pending_email_address(c).should == "jack@example.com"
      end
    end


end