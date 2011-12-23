require 'net/http'
require 'cgi'
require 'db'
require 'json'

def id_language(text)
  `perl lang.pl "#{text}"`
end

def progress(langs, i, all)
  puts langs.keys.zip(langs.values.map(&:length)).inspect
  printf("%0.2f percent complete\n", 100*(i.to_f/all))
end

LOG_FILE = "language_log.txt"

records = ActionLog.all(:select => "query, sesid", :limit => 1000)
languages = {}

records.each_with_index do |record, i|
  text = record.query
  next if text.nil? || text.empty?
  lang = id_language(text)
  if languages[lang] == nil
    languages[lang] = [record.sesid]
  else
    languages[lang] << record.sesid
  end
  progress(languages, i, records.length) if i%10 == 0
end

File.open(LOG_FILE, 'w') do |f|
  f.puts languages.keys.join(',')
  f.puts languages.values.map(&:length).join(',')
  f.puts languages.values.map(&:uniq!).map(&:length).join(',')
end
