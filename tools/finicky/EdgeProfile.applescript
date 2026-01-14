-- EdgeProfile.applescript
-- Opens URLs in Microsoft Edge with a specific profile
--
-- To compile this into an app:
--   osacompile -o ~/Applications/EdgeProfile.app EdgeProfile.applescript
--
-- Then in your .finicky.js, use:
--   browser: "EdgeProfile"
--
-- IMPORTANT: Update profileDir below to match your Edge profile directory

-- Change "Profile 1" to your actual Edge profile directory name
property profileDir : "Profile 1"

-- Handle URLs passed via "open location" (URL scheme)
on open location theURL
    openInEdge(theURL)
end open location

-- Handle URLs passed as file/document arguments
on open theItems
    repeat with theItem in theItems
        set theURL to theItem as text
        openInEdge(theURL)
    end repeat
end open

-- Handle command line arguments (when launched with URL as arg)
on run argv
    if (count of argv) > 0 then
        repeat with theArg in argv
            openInEdge(theArg as text)
        end repeat
    else
        display dialog "EdgeProfile: This app opens URLs in Microsoft Edge with Profile 1. It should be called via Finicky." buttons {"OK"} default button "OK"
    end if
end run

-- Main function to open URL in Edge with profile
on openInEdge(theURL)
    -- Use open -na to force new instance that respects profile arg
    do shell script "open -na 'Microsoft Edge' --args --profile-directory='" & profileDir & "' '" & theURL & "'"
end openInEdge
