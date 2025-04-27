set todaysDate to current date
set hours of todaysDate to 0
set minutes of todaysDate to 0
set seconds of todaysDate to 0
set tomorrowDate to todaysDate + (1 * days)

tell application "Calendar"
    tell calendar "Calendar"
        set todaysEvents to every event whose start date ≥ todaysDate and start date < tomorrowDate
        repeat with evt in todaysEvents
            log "Found event: " & (summary of evt) & " at " & (start date of evt as string)
        end repeat
        
        if (count of todaysEvents) > 0 then
            show first event of todaysEvents
        end if
    end tell
end tell

