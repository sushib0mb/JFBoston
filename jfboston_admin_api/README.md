# JFBoston-Admin API
A helper app for JFBoston, designed to give access to admin controls such as modifying timetables

## Finding Scheduled Performances
All schedule items can be fetched regardless of stage, or an optional parameter can be used to select which stage items are fetched

## Fixing Schedule Delays
### Delaying a Single Performance
If a single performance needs to be delayed, a delay function with a performance id and minutes input to delay the chosen performance's start time

### Delaying All Subsequent Performances
If a delay affects all future performances, a shuffle function with a performance id and minutes input can be used to delay the chosen performance and all subsequent performances at the same stage
