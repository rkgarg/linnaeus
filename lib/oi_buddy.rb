require 'rubygems'
require 'linnaeus'
require 'net/http'
require 'json'

class OiBuddy

  attr_accessor :trainer, :classify

  CONTEXT_MAPS = {
    :stay_room_service =>  [%w(room bedsheet linen fridge tv television towel toilet bathroom tooth paste toothpaste manager luggage bell-boy ), %w(bring get service)],
    :stay_emergency => [%w(police ambulance thief  doctor), %w(stole)],
    :stay_laundry => [%w( laundry  clothes detergent shirt jeans), %w(clean wash )],
    :stay_beverage => [%w(coffee tea  water beverage  milk juice), %w(order bring drinks)],
    :stay_taxi => [%w( cab taxi ola uber tfs car), %w(order reach book)],
    :stay_breakfast => [%w( breakfast lunch cornflakes menu bread butter food morning complimentary), %w(eat )],
    :stay_lunch_dinner => [%w(lunch menu dinner price), %w(eat)],
    :stay_nearby_food => [%w(restaurant  zomato food  pizza continental chinese indian), %w(nearby outside order eat )],
    :stay_nearby_travel => [%w( places  tourism   temples park mall), %w(nearby visit travel tourist historic)],
    :stay_extend => [%w( booking extra ), %w(extend stay lengthen)],
    :stay_money => [%w(amount money  wallet  price), %w(pay checkout)],
    :stay_weather => [%w(weather rain sunny sunset ), %w(forecast)],
    :stay_wifi => [%w(internet wifi wi-fi wireless network password username), %w(connect )],
    :stay_directions => [%w(location oyo latitude longitude maps), %w(route direction navigate nearest )]
  }

  def initialize()
    self.trainer  = ::Linnaeus::Trainer.new(scope: "test3")    # Used to train documents
    self.classify = ::Linnaeus::Classifier.new(scope: "test3")   # Used to classify documents
  end

  def feed_data
    CONTEXT_MAPS.each do |context,kwords|
      all_resp = []
      kwords[0].each{ |s| all_resp.concat(weighted_synonyms(s,false)) }
      kwords[1].each{ |s| all_resp.concat(weighted_synonyms(s,true)) }

      puts "Training #{context} => #{all_resp.join(' ,')}"
      all_resp.each do |s|
        self.trainer.train context,s.to_s
      end
    end
  end

  def get_context input
    res, matches, total_count = self.classify.classify(input)
    if matches >= 2 || (matches.to_f/total_count) > 0.2
      return {status: 'true', result: res}
    else
      return {status: 'false', response: 'Not enough data. Please try something else'}
    end
  end


  private

  def weighted_synonyms keyword, is_verb
    syns = []
    resp = Net::HTTP.get(URI.parse(URI.encode("http://words.bighugelabs.com/api/2/c5bf29b078e8f26316be77aeab9203bd/"+keyword+"/json")))
    resp = JSON.parse resp rescue nil

    puts resp

    #handle noun
    max = is_verb ? 2:5
    syns.concat(get_words_with_weights(resp.delete('noun'),max))

    #handle verb
    max = is_verb ? 5:2
    syns.concat(get_words_with_weights(resp.delete('verb'),max))

    resp.each do |k,v|
      syns.concat(get_words_with_weights(v,3))
    end

    syns.concat([keyword]*7)
    puts "synonms for #{keyword} => #{syns}"
    syns.flatten.uniq
  rescue => e
    syns
  end

  def get_words_with_weights response,max_value
    return if response.nil?
    arr = []
    words = (response).values.flatten.uniq.first(max_value)
    words.each_with_index{|a,i| arr.concat([a]*(max_value-i))}
    return arr
  end

end

