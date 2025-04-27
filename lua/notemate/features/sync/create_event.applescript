#!/usr/bin/osascript

on run argv
    if (count of argv) < 3 then
        return "Error: Not enough arguments. Need title, start time, and end time."
    end if
    
    set eventTitle to item 1 of argv
    set startTimeStr to item 2 of argv
    set endTimeStr to item 3 of argv
    
    set eventDescription to ""
    if (count of argv) > 3 then
        set eventDescription to item 4 of argv
    end if
    
    -- Convert string dates to date objects
    set startDate to date startTimeStr
    set endDate to date endTimeStr
    
    tell application "Calendar"
        set defaultCal to calendar "Calendar" -- Modify this if you use a different calendar
        
        -- Check if an event with the same title and time already exists
        set existingEvents to (every event of defaultCal whose summary is eventTitle and start date is startDate and end date is endDate)
        
        if (count of existingEvents) is 0 then
            -- Create the new event
            tell defaultCal
                make new event with properties {summary:eventTitle, start date:startDate, end date:endDate, description:eventDescription}
                save -- THIS IS CRUCIAL
                return "Event created: " & eventTitle
            end tell
        else
            return "Event already exists: " & eventTitle
        end if
    end tell
end run

