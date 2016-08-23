
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then 
		Return;
	EndIf;

	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	DeferredUpdateStartTime = UpdateDetails.DeferredUpdateStartTime;
	DeferredUpdateEndTime = UpdateDetails.DeferredUpdateEndTime;
	CurrentSessionNumber = UpdateDetails.SessionNumber;
	FileInfobase = CommonUse.FileInfobase();
	
	If Not Users.InfobaseUserWithFullAccess(, True) Then
		Items.RestartGroup.Visible = False;
	EndIf;
	
	If Not FileInfobase Then
		UpdateInProgress = (UpdateDetails.DeferredUpdateCompletedSuccessfully = Undefined);
	EndIf;
	
	If Not Users.RolesAvailable("ViewEventLog") Then
		Items.DeferredUpdateHyperlink.Visible = False;
	EndIf;
	
	Status = "AllProcedures";
	
	UpdateDeferredHandlersTable();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UpdateInProgress Then
		AttachIdleHandler("UpdateHandlersTable", 15);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure CloseForm(Command)
	Close();
EndProcedure

&AtClient
Procedure RunAgain(Command)
	Notify("DeferredUpdate");
	Close();
EndProcedure

&AtClient
Procedure DeferredUpdateHyperlinkClick(Item)
	
	If ValueIsFilled(DeferredUpdateStartTime) And ValueIsFilled(DeferredUpdateEndTime) Then
		FormParameters = New Structure;
		FormParameters.Insert("StartDate", DeferredUpdateStartTime);
		FormParameters.Insert("EndDate", DeferredUpdateEndTime);
		FormParameters.Insert("Session", CurrentSessionNumber);
		
		OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	Else
		
		If ValueIsFilled(DeferredUpdateStartTime) Then
			WarningText = NStr("en = 'Data processing is not completed yet.'");
		Else
			WarningText = NStr("en = 'Data processing has not been executed.'");
		EndIf;
		
		ShowMessageBox(,WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	UpdateDeferredHandlersTable();
	If DeferredHandlers.Count() > 0 Then
		Items.DeferredHandlers.CurrentRow = DeferredHandlers[0].GetID();
	EndIf;
EndProcedure

&AtClient
Procedure SearchStringOnChange(Item)
	UpdateDeferredHandlersTable();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure UpdateHandlersTable()
	
	AllHandlersExecuted = True;
	UpdateDeferredHandlersTable(AllHandlersExecuted);
	If AllHandlersExecuted Then
		DetachIdleHandler("UpdateHandlersTable");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDeferredHandlersTable(AllHandlersExecuted = True)
	
	DeferredHandlers.Clear();
	HandlersNotExecuted = True;
	UpdateDetails = InfobaseUpdateInternal.InfobaseUpdateDetails();
	
	For Each TreeRowLibrary In UpdateDetails.HandlerTree.Rows Do
		For Each TreeRowVersion In TreeRowLibrary.Rows Do
			For Each HandlerRow In TreeRowVersion.Rows Do
				
				If Status <> "AllProcedures"
					And Not HandlerRow.Status = Status Then
					Continue;
				EndIf;
				
				If Not IsBlankString(SearchString) Then
					If Not IsBlankString(HandlerRow.Comment) Then
						If Find(Upper(HandlerRow.Comment), Upper(SearchString)) = 0 Then
							Continue;
						EndIf;
					Else
						If Find(Upper(HandlerRow.HandlerName), Upper(SearchString)) = 0 Then
							Continue;
						EndIf;
					EndIf;
				EndIf;
				
				ListRow = DeferredHandlers.Add();
				If Not IsBlankString(HandlerRow.Comment) Then
					ListRow.Handler = HandlerRow.Comment;
				Else
					ListRow.Handler = HandlerRow.HandlerName;
				EndIf;
				
				If HandlerRow.Status = "Completed" Then
					HandlersNotExecuted = False;
					ListRow.UpdateProcessInformation = 
						NStr("en = 'The %1 update procedure completed successfully.'");
					ListRow.HandlerStatus = NStr("en = 'Executed'");
					ListRow.Weight = 1;
					ListRow.StatusPicture = PictureLib.Done;
				ElsIf HandlerRow.Status = "Executing" Then
					HandlersNotExecuted = False;
					ListRow.UpdateProcessInformation = 
						NStr("en = 'Executing the %1 update procedure'");
					ListRow.HandlerStatus = NStr("en = 'Executing'");
					ListRow.Weight = 3;
				ElsIf HandlerRow.Status = "Error" Then
					HandlersNotExecuted = False;
					AllHandlersExecuted = False;
					ListRow.UpdateProcessInformation = HandlerRow.ErrorInfo;
					ListRow.HandlerStatus = NStr("en = 'Error'");
					ListRow.Weight = 4;
					ListRow.StatusPicture = PictureLib.Stop;
				Else
					AllHandlersExecuted = False;
					ListRow.HandlerStatus = NStr("en = 'Has not been executed'");
					ListRow.Weight = 2;
					ListRow.UpdateProcessInformation = NStr("en = 'The %1 update procedure has not been executed.'");
				EndIf;
				
				ListRow.UpdateProcessInformation = StringFunctionsClientServer.SubstituteParametersInString(
					ListRow.UpdateProcessInformation, HandlerRow.HandlerName);
				
			EndDo;
		EndDo;
	EndDo;
	
	If AllHandlersExecuted Or UpdateInProgress Then
		Items.RestartGroup.Visible = False;
	EndIf;
	
	If HandlersNotExecuted Then
		Items.ExplanationText.Title = NStr("en = 'It is recommended to start update procedures that have not been executed.'");
	Else
		Items.ExplanationText.Title = NStr("en = 'It is recommended to restart update procedures that have not been executed.'");
	EndIf;
	
	DeferredHandlers.Sort("Weight Desc");
	
	ItemNumber = 1;
	For Each TableRow In DeferredHandlers Do
		TableRow.Number = ItemNumber;
		ItemNumber = ItemNumber + 1;
	EndDo;
	
	Items.UpdateInProgress.Visible = UpdateInProgress;
	
EndProcedure

#EndRegion
