require 'csv'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phone_number(phone)
  phone = phone&.gsub(/\D/,'')

  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == '1'
    phone[0..9]
  else
    phone = '0000000000'
  end
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exists? 'output'

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager Initialized!'

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

def create_letters(contents, erb_template)
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone = clean_phone_number(row[:homephone])

    form_letter = erb_template.result(binding)

    save_thank_you_letters(id, form_letter)
  end
end

def most_frequent_registration_periods(contents)
  registration_periods = []

  contents.each do |row|
    registration_periods << DateTime.strptime(row[:regdate],'%m/%d/%Y %H:%M')
  end

  registration_times = registration_periods.inject(Hash.new(0)) { |hash, time| hash[time.hour] += 1; hash }
  registration_days = registration_periods.inject(Hash.new(0)) { |hash, time| hash[time.strftime('%A')] += 1; hash }
  puts "Ranking of hours of the day: #{registration_times.sort_by { |time, frequency| -frequency }.to_h}"
  puts "Ranking of days of the week: #{registration_days.sort_by { |time, frequency| -frequency }.to_h}"
end

most_frequent_registration_periods(contents)
create_letters(contents, erb_template)
