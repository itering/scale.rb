module Scale
  module Types

    class IntOrBool
      include Enum
      items(
        Int: 'Scale::Types::U8',
        Bool: 'Scale::Types::Bool'
      )
    end

    class RewardDestination
      include Enum
      values "Staked", "Stash", "Controller"
    end

  end
end
