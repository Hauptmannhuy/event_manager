require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def peak_hour(date)
 reformed_date = date.to_s.each_char do |char|
    if date[char] == ' '
      index = date.index(char)
      date.insert(index, '/')
    end
  end
   reformed_date = reformed_date.split('/')
   if reformed_date[1] > "12"
    reformed_date[0],reformed_date[1] = reformed_date[1],reformed_date[0] 
   end
   
   time = Time.parse(reformed_date.join('/'))
end

def clean_phone_number(number)
  formatted = ''
   number.each_char do |digit|
    if ('1234567890').include?(digit)
      formatted << digit
   end
  end
  #  formatted.length == 10 || (formatted.length == 11 && formatted[0] == '1') ? formatted[0..] : 'bad number'
    if formatted.length < 10
      formatted = 'bad number'
    elsif
      formatted.length == 11 && formatted[0] == '1'
      formatted.slice!(0)
    elsif formatted.length == 11 && formatted[0] != '1'
      formatted = 'bad number'
    elsif formatted.length > 11
      formatted = 'bad number'
    end
    formatted
end


def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

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
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  
  form_letter = erb_template.result(binding)
  home_phone = clean_phone_number(row[:homephone])
  date = peak_hour(row[:regdate])
  puts date
  #  save_thank_you_letter(id,form_letter)
end

