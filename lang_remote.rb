require 'net/http'
require 'cgi'
require 'db'
require 'json'

def id_language(text)
  url = URI.parse("http://ajax.googleapis.com/ajax/services/language/detect?v=1.0&q=#{CGI::escape(text)}")
  res = Net::HTTP.new(url.host, url.port)
  res.read_timeout = 0.5 
  begin
    res = res.request(Net::HTTP::Get.new(url.request_uri))
  rescue Timeout::Error
    puts "timeout\n"
    sleep 5 
    retry
  end
  if res.is_a?(Net::HTTPSuccess)
    data = JSON.parse(res.body)['responseData']
    return nil if data.nil?
    return [data['language'], data['confidence'].to_f, data['isReliable']]
  end
  false
end

def progress(langs, i, all)
  puts langs.keys.zip(langs.values.map { |o| o.length - 1 }).inspect
  printf("%0.2f percent complete\n", 100*(i.to_f/all))
end

LOG_FILE = "language_log.txt"

records = ActionLog.all(:select => "query, sesid")#, :limit => 1000)
languages = {}

records.each_with_index do |record, i|
  text = record.query
  next if text.nil? || text.empty?
  result = id_language(text)
  next if result.nil?
  lang, confidence, reliable = result
  if languages[lang] == nil
    languages[lang] = [reliable == 'true' ? 1 : 0, [record.sesid, confidence]]
  else
    languages[lang][0] += 1 if reliable == 'true'
    languages[lang] << [record.sesid, confidence]
  end
  progress(languages, i, records.length) #if i%10 == 0
end

def count_with_threshold(values, threshold = 0)
  values.map { |sessions| sessions.reject { |item| item.last < threshold } }.map(&:length)
end

File.open(LOG_FILE, 'w') do |f|
  f.puts languages.keys.join(',')
  values = languages.values
  f.puts values.map(&:first).join(',')
  values.map(&:shift)
  f.puts count_with_threshold(values).join(',')
  f.puts count_with_threshold(values, 0.10).join(',')
  f.puts count_with_threshold(values, 0.25).join(',')
  f.puts count_with_threshold(values, 0.5).join(',')
  f.puts count_with_threshold(values, 0.75).join(',')
  values.map(&:uniq!)
  f.puts count_with_threshold(values).join(',')
  f.puts count_with_threshold(values, 0.10).join(',')
  f.puts count_with_threshold(values, 0.25).join(',')
  f.puts count_with_threshold(values, 0.5).join(',')
  f.puts count_with_threshold(values, 0.75).join(',')
end
