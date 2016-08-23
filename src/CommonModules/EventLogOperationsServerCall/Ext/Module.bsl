////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Procedures and functions for working with the event log.
//
//////////////////////////////////////////////////////////////////////////////// 

#Region Interface

// Handles bunch message writing to the event log.  
//
// Parameters:
//  EventsForEventLog - ValueList - global client variable. Once the data is written
//                      the variable is cleared.
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	EventLogOperations.WriteEventsToEventLog(EventsForEventLog);
	
EndProcedure

#EndRegion