module TweetImporterHelper
  
  # TODO: IMPROVE
  def clean_tweet_text(text)
    puts '------------------------------------------------'
    puts text
    # delete all these characters
    text = text.tr('():', '')
    text_ary = text.split(' ')
    # delete all these characters if the occur as a single token
    text_ary.delete('.')
    text_ary.delete('?')
    text_ary.delete('!')
    text_ary.delete(',')
    text_ary.delete('-')
    # remove @user and #hash tokens      
    text_ary.select! {|token| token if !token.start_with? '@' and !token.start_with? '#'}
    # strip each token and lower it
    text_ary.each_with_index do |token, i|
      text_ary[i] = strip_token(token, ',.!?')
    end
    text = text_ary.join(' ')
    text.downcase!
    puts text
    return text
  end
  
  def strip_token(string, chars)
    chars = Regexp.escape(chars)
    string.gsub(/\A[#{chars}]+|[#{chars}]+\Z/, "")
  end
  
end
