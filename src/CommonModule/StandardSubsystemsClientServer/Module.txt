////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Execution result processing.

// Generates the execution result pattern.
//
// Returns: 
//  Result - Structure - see StandardSubsystemsClient.ShowExecutionResult() for details.
//
Function NewExecutionResult(Result = Undefined) Export
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	Result.Insert("NotificationOutput",      New Structure("Use, Title, Ref, Text, Picture", False));
	Result.Insert("MessageOutput",           New Structure("Use, Text, PathToFormAttribute", False));
	Result.Insert("WarningOutput",           New Structure("Use, Title, Text, PathToFormAttribute, ErrorText", False));
	Result.Insert("FormNotification",        New Structure("Use, EventName, Parameter, Source", False));
	Result.Insert("DynamicListNotification", New Structure("Use, ReferenceOrType", False));
	
	Return Result;
EndFunction

// Adds notifications for updating dynamic lists by the array of object references.
//
// Parameters:
//   ModifiedObjects - Array - modified object references.
//   Result          - Structure - see StandardSubsystemsClient.ShowExecutionResult()
//                     for details.
//
Procedure PrepareDynamicListNotification(ModifiedObjects, Result) Export
	If TypeOf(ModifiedObjects) <> Type("Array") Or ModifiedObjects.Count() = 0 Then
		Return;
	EndIf;
	
	Notification = Result.DynamicListNotification;
	Notification.Use = True;
	
	Value = Notification.ReferenceOrType;
	ValueIsFilled = ValueIsFilled(Value);
	
	If ModifiedObjects.Count() = 1 And Not ValueIsFilled Then
		Notification.ReferenceOrType = ModifiedObjects[0];
	Else
		// Transforming the notification into an array.
		ValueType = TypeOf(Value);
		If ValueType <> Type("Array") Then
			Notification.ReferenceOrType = New Array;
			If ValueIsFilled Then
				Notification.ReferenceOrType.Add(?(ValueType = Type("Type"), Value, ValueType));
			EndIf;
		EndIf;
		
		// Adding types of the modified objects.
		For Each ModifiedObject In ModifiedObjects Do
			ChangedObjectType = TypeOf(ModifiedObject);
			If Notification.ReferenceOrType.Find(ChangedObjectType) = Undefined Then
				Notification.ReferenceOrType.Add(ChangedObjectType);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

// Adds notifications for updating dynamic lists by the array of changed objects.
//
// Parameters:
//   Result    - Structure - see StandardSubsystemsClient.ShowExecutionResult() for
//               details.
//   EventName - String - name of the event used for primary message identification
//               be the receiver.
//   Parameter - Arbitrary - set of data used by the receiver for updating the
//               content.
//   Source    - Arbitrary - notification source, for example, a source form.
//
Procedure ExecutionResultAddOpenFormNotification(Result, EventName, Parameter = Undefined, Source = Undefined) Export
	If Not Result.Property("FormNotification") Then
		Result.Insert("FormNotification", New Array);
	ElsIf TypeOf(Result.FormNotification) = Type("Structure") Then // Structure into Array of Structure
		FormNotification = Result.FormNotification;
		Result.FormNotification = New Array;
		Result.FormNotification.Add(FormNotification);
	EndIf;
	FormNotification = New Structure("Use, EventName, Parameter, Source", True, EventName, Parameter, Source);
	Result.FormNotification.Add(FormNotification);
EndProcedure

#EndRegion
