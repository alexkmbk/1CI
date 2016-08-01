#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region InternalInterface

// Updates software event parameters when the configuration is changed.
// 
// Parameters:
//  HasChanges - Boolean (return value) - is set to True if changes saved, otherwise
//               is False.
//
Procedure Update(HasChanges = Undefined, CheckOnly = False) Export
	
	SetPrivilegedMode(True);
	
	If CheckOnly Or ExclusiveMode() Then
		DisableExclusiveMode = False;
	Else
		DisableExclusiveMode = True;
		SetExclusiveMode(True);
	EndIf;
	
	EventHandlers = StandardSubsystemsServer.EventHandlers();
	
	DataLock = New DataLock;
	LockItem = DataLock.Add("Constant.InternalEventParameters");
	LockItem.Mode = DataLockMode.Exclusive;
	
	BeginTransaction();
	Try
		DataLock.Lock();
		
		Parameters = StandardSubsystemsServer.ApplicationParameters(
			"InternalEventParameters");
		
		Saved = Undefined;
		
		If Parameters.Property("EventHandlers") Then
			Saved = Parameters.EventHandlers;
			
			If Not CommonUse.IsEqualData(EventHandlers, Saved) Then
				Saved = Undefined;
			EndIf;
		EndIf;
		
		If Saved = Undefined Then
			HasChanges = True;
			If CheckOnly Then
				CommitTransaction();
				Return;
			EndIf;
			StandardSubsystemsServer.SetApplicationParameter(
				"InternalEventParameters", "EventHandlers", EventHandlers);
		EndIf;
		
		StandardSubsystemsServer.ConfirmApplicationParametersUpdate(
			"InternalEventParameters", "EventHandlers");
		
		CommitTransaction();
	Except
		RollbackTransaction();
		If DisableExclusiveMode Then
			SetExclusiveMode(False);
		EndIf;
		Raise;
	EndTry;
	
	If DisableExclusiveMode Then
		SetExclusiveMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
