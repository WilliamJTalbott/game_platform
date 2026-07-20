# Plan

    Update 'End of Game' system architecture
    Fix History and Stats updating. (Needs to only show info on finished games)
    Bad Auth and Bad Request specs needed
    Only Host can start game.
    Game lobby page instead of waiting on game page.

    Add optimistic-locking fix. For stale browsers, keystone bug
    
    Add turn-state awareness UI. 
    Fix Books display
    Fix End State UI
    Add shared game engine to reduce code duplication
    
# End of Game

    Finish partial displayed ontop of game page using stimulus.
    For now jsut shows the winner and the losers listed scroeboard style
    Button to return to menu, view your post game stats, or create a new game.
    Need to ensure that game page is no longer usable.