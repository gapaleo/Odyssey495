class ReportsController < ApplicationController  
  before_action :logged_in
  before_action :admin_or_standard

  

#Render the html page, mapquest csv, or pdf files. csv and pdf downloads are in pickup.rb
  def truck
    respond_to do |format|
      format.html {
        
        #Used to populate the dropdown menu in the truck report form. Only shows 
        #current and future days that have scheduled pickups
        temp = []
        Day.all.each do |d|
          if !d.pickups.empty? && d.date >= Date.today
            temp.push(d)
          end
        end
        @days = temp.sort_by{|d| d.date}
      }
      format.pdf {
        
        #Query returns all the pickups for the given date that have not been rejected
        pickups = Pickup.joins(:day).where("date = ?", params[:pickupday]).where("rejected = ?", false)
        
        #Sends pdf file to the browser. File is
        #generated by the to_pdf function inside our Pickup model. Takes the
        #date as an argument.
        send_data pickups.to_pdf(params[:pickupday]), 
        filename: "truck_#{filename_date(params[:pickupday])}.pdf", 
        type: "application/pdf"
      }
    end
  end

  def mapquest
    respond_to do |format|
      format.html {

        #Used to populate the dropdown menu in the truck report form. Only shows 
        #current and future days that have scheduled pickups
        temp = []
        Day.all.each do |d|
          if !d.pickups.empty? && d.date >= Date.today
            temp.push(d)
          end
        end
        @days = temp.sort_by{|d| d.date}
      }
      format.csv {
        
        #Query returns all the pickups for the given date that have not been rejected
        pickups = Pickup.joins(:day).where("date = ?", params[:pickupday]).where("rejected = ?", false)
        
        #Sends csv file to the browser. File is
        #generated by the to_routes_csv function inside our Pickup model. 
        send_data pickups.to_routes_csv, 
        filename: "mapquest_#{filename_date(params[:pickupday])}.csv"
      }
    end
  end
  
  #Render html page or export donor csv file
  def donor
      respond_to do |format|
        format.html
        format.csv { 
          headers = ["Title", "First", "Spouse", "Last", "Address", "Town",
                    "State", "Zip", "Phone", "E-Mail", "Date Donated", "Items Donated"]
                    
          #Creates array with given values.
          attributes = %w{donor_title donor_first_name donor_spouse_name donor_last_name address
                          donor_city donor_state donor_zip donor_phone donor_email
                          date item_notes}

          #Generate csv file
          csvFile = CSV.generate(headers: true) do |csv|
            csv << headers
            Day.all.each do |d|
              if  d.date.year.to_s ==  params[:date][:year] && d.date.mon.to_s == params[:date][:month]
                
                #Add donor info of all the pickups from the month and year specified on the 
                #form where the dwelling type is Current Residence to the the csv file
                d.pickups.all.each do |p|
                  if p.donor_dwelling_type == "Current Residence" && p.rejected == false
                    csv << attributes.map{ |attr| p.send(attr) }
                  end
                end
              end
            end
          end
          
          #Sends csv file to the browser.
          send_data csvFile, filename:
          "donors_#{month_name(params[:date][:month])}#{params[:date][:year]}.csv"
        }
      end
  end
  
  #get rejected pickups from specified month and year
  def rejected
      respond_to do |format|
        format.html
        format.csv { 
    headers = ["Title", "First", "Last", "Phone", "E-Mail", "Address 1", "Address 2", "City",
               "State", "Zip", "Rejected Reason", "Rejected Date"]

          #Creates array with given values.
          attributes = %w{donor_title donor_first_name donor_last_name donor_phone donor_email
                          donor_address_line1 donor_address_line2 donor_city donor_state donor_zip 
                          rejected_reason rejected_date}
                          
          csvFile = CSV.generate(headers: true) do |csv|
            csv << headers
            Pickup.all.each do |p|
              
              #Add info of all the pickups that were rejected at the month and year specified on the 
              #form the the csv file
              if p.rejected == true  && p.updated_at.mon.to_s == params[:date][:month] && p.updated_at.year.to_s == params[:date][:year]
                csv << attributes.map{ |attr| p.send(attr) }
              end
            end
          end
          
          #Sends csv file to the browser.
          send_data csvFile, filename:
          "rejected_#{month_name(params[:date][:month])}#{params[:date][:year]}.csv"
        }
      end
  end

  private 
  #get 3 letter month abreviation from month number
  def month_name(number)
    case number
    when "1"
      return "jan"
    when "2"
      return "feb"
    when "3"
      return "mar"
    when "4"
      return "apr"
    when "5"
      return "may"
    when "6"
      return "jun"
    when "7"
      return "jul"
    when "8"
      return "aug"
    when "9"
      return "sep"
    when "10"
      return "oct"
    when "11"
      return "nov"
    when "12"
      return "dec"
    end
  end

  #generate the file name for truck reports
  def filename_date(date)
    Date.parse(date).strftime("%b%-d").downcase
  end
end