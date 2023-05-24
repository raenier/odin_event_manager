require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zip(zip)
  zip.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number = number.gsub(/[^0-9A-Za-z]/, '')
  return number if number.length == 10
  return "Bad Phone number: #{number}" if number.length < 10 || number.length > 11 || number[0] != '1'

  number.slice(1, number.length)
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'Yeah Dumbass pass a real zipcode'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename= "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

# --------------------------------------

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  p clean_phone_number(row[:homephone])

  zipcode = clean_zip(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  #output to a file
  save_thank_you_letter(id, form_letter)
end
