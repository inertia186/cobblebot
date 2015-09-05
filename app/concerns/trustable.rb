module Trustable
  extend Commandable
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def rate(truster_nick, trustee_nick, rate_integer)
      truster ||= Player.find_by_nick(truster_nick)
      return if truster.nil?
      
      unless truster.registered?
        tell(truster.nick, 'Sorry, you can only rate other players if you are registered.')
        return
      end

      if trustee_nick =~ /@/
        tell(truster.nick, 'Sorry, you can only rate specific players.')
        return
      end

      Player.best_match_by_nick(trustee_nick, no_match: -> {
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(truster_nick, trustee_nick, command: "@server rate %nick% ")
      }) do |trustee|
        reputation = truster.inverse_reputations.find_or_create_by(trustee: trustee)
        old_rate_integer = reputation.rate
        
        if old_rate_integer != rate_integer
          reputation.rate = rate_integer.to_i
          if reputation.save
            tell(truster.nick, "Success.  Changed from #{old_rate_integer} to #{rate_integer}.")
          else
            tell(truster.nick, escape(reputation.errors.full_messages.inspect))
          end
        else
          tell(truster.nick, "No change.")
        end
      end
    end

    def votekick(voter_nick, nick)
      voter ||= Player.find_by_nick(voter_nick)
      return if voter.nil?
      
      unless voter.registered?
        tell(voter.nick, 'Sorry, you can only votekick if you are registered.')
        return
      end

      if nick =~ '@'
        tell(voter.nick, 'Sorry, you can only votekick specific players.')
        return
      end
      
      Player.best_match_by_nick(nick, no_match: -> {
        # FIXME The 'command' option should come from the callback record, not hardcoded.
        say_nick_not_found(voter_nick, nick, command: "@server votekick %nick%")
      }) do |recipient|
        tell(voter.nick, 'Vote registered.  Do not abuse this feature.')
      end
    end
  end
end