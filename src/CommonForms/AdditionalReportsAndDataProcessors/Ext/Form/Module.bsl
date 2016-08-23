&AtClient
Var HandlerParameters;

&AtClient
Var CommandToExecute;

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	If Parameters.Property("WindowOpeningMode") Then
		ThisObject.WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	
	If ValueIsFilled(Parameters.SectionName)
		And Parameters.SectionName <> AdditionalReportsAndDataProcessorsClientServer.DesktopID() Then
		SectionRef = CommonUse.MetadataObjectID(Metadata.Subsystems.Find(Parameters.SectionName));
	EndIf;
	
	DataProcessorKind = AdditionalReportsAndDataProcessors.GetDataProcessorKindByKindStringPresentation(Parameters.Kind);
	
	If DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.ObjectFilling Then
		AreAssignableDataProcessors = True;
		Title = NStr("en = 'Commands for object filling'");
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.Report Then
		AreAssignableDataProcessors = True;
		AreReports = True;
		Title = NStr("en = 'Reports'");
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.PrintForm Then
		AreAssignableDataProcessors = True;
		Title = NStr("en = 'Additional print forms'");
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.RelatedObjectCreation Then
		AreAssignableDataProcessors = True;
		Title = NStr("en = 'Commands of related object creation'");
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalDataProcessor Then
		AreGlobalDataProcessors = True;
		Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Additional data processors (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	ElsIf DataProcessorKind = Enums.AdditionalReportAndDataProcessorKinds.AdditionalReport Then
		AreGlobalDataProcessors = True;
		AreReports = True;
		Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Additional reports (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	EndIf;
	
	If Parameters.Property("Title") Then
		Title = Parameters.Title;
	EndIf;
	
	If AreAssignableDataProcessors Then
		Items.CustomizeList.Visible = False;
		
		TargetObjects.LoadValues(Parameters.TargetObjects.UnloadValues());
		
		OwnerFormName = Parameters.FormName;
		OwnerInfo = AdditionalReportsAndDataProcessorsCached.AssignedObjectFormParameters(OwnerFormName);
		
		If TypeOf(OwnerInfo) = Type("FixedStructure") Then
			ParentRef    = OwnerInfo.ParentRef;
			IsObjectForm = OwnerInfo.IsObjectForm;
		Else
			ParentMetadata = Metadata.FindByType(TypeOf(TargetObjects[0].Value));
			ParentRef    = CommonUse.MetadataObjectID(ParentMetadata);
			IsObjectForm = False;
		EndIf;
	EndIf;
	
	FillDataProcessingTable();
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)
	If SelectedValue = "MyReportsAndDataProcessorsSetupDone" Then
		FillDataProcessingTable();
	EndIf;
EndProcedure

&AtClient
Procedure OnClose()
	If BackgroundJobCheckExecutionOnClose Then
		BackgroundJobCheckExecutionOnClose = False;
		DetachIdleHandler("CheckBackgroundJobExecution");
		
		Result = CheckBackgroundJobExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, True);
		If Result.Completed Or Result.ExceptionRaised Then
			ShowDataProcessorsExecutionResult(Result, False);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemEventHandlersCommandTable

&AtClient
Procedure CommandTableChoice(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ExecuteByParameters();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteCommand(Command)
	
	ExecuteByParameters()
	
EndProcedure

&AtClient
Procedure CustomizeList(Command)
	Opening = New Structure("Name, Parameters, Owner, Uniqueness, Window");
	
	Opening.Name = "CommonForm.MyReportsAndDataProcessorsSetup";
	Opening.Owner = ThisObject;
	Opening.Uniqueness = False;
	
	Opening.Parameters = New Structure("DataProcessorKind, AreGlobalDataProcessors, CurrentSection");
	Opening.Parameters.DataProcessorKind       = DataProcessorKind;
	Opening.Parameters.AreGlobalDataProcessors = AreGlobalDataProcessors;
	Opening.Parameters.CurrentSection          = SectionRef;
	
	OpenForm(Opening.Name, Opening.Parameters, Opening.Owner, Opening.Uniqueness, Opening.Window);
EndProcedure

&AtClient
Procedure CancelProcessing(Command)
	Close();
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillDataProcessingTable()
	Query = AdditionalReportsAndDataProcessors.NewQueryByAvailableCommands(DataProcessorKind, ?(AreGlobalDataProcessors, SectionRef, ParentRef), IsObjectForm);
	
	ResultTable = Query.Execute().Unload();
	
	ValueToFormAttribute(ResultTable, "CommandTable");
EndProcedure

&AtClient
Procedure ExecuteByParameters()
	DataProcessorData = Items.CommandTable.CurrentData;
	If DataProcessorData = Undefined Then
		Return;
	EndIf;
	
	CommandToExecute = New Structure(
		"Ref, Presentation, ID, RunningVariant, ShowNotification, Modifier, TargetObjects, IsReport, Kind");
	FillPropertyValues(CommandToExecute, DataProcessorData);
	If Not AreGlobalDataProcessors Then
		CommandToExecute.TargetObjects = TargetObjects.UnloadValues();
	EndIf;
	CommandToExecute.IsReport = AreReports;
	CommandToExecute.Kind     = DataProcessorKind;
	
	If DataProcessorData.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.FormOpening") Then
		
		AdditionalReportsAndDataProcessorsClient.OpenDataProcessorForm(CommandToExecute, FormOwner, CommandToExecute.TargetObjects);
		Close();
		
	ElsIf DataProcessorData.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ClientMethodCall") Then
		
		AdditionalReportsAndDataProcessorsClient.ExecuteDataProcessorClientMethod(CommandToExecute, FormOwner, CommandToExecute.TargetObjects);
		Close();
		
	ElsIf DataProcessorKind = PredefinedValue("Enum.AdditionalReportAndDataProcessorKinds.PrintForm")
		And DataProcessorData.Modifier = "PrintMXL" Then
		
		AdditionalReportsAndDataProcessorsClient.OpenPrintForm(CommandToExecute, FormOwner, CommandToExecute.TargetObjects);
		Close();
		
	ElsIf DataProcessorData.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ServerMethodCall")
		Or DataProcessorData.RunningVariant = PredefinedValue("Enum.AdditionalDataProcessorCallMethods.ScenarioInSafeMode") Then
		
		// Changing form items
		Items.ExplainingDecoration.Title = StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Executing command: ""%1""...'"),
			DataProcessorData.Presentation);
		Items.Pages.CurrentPage = Items.DataProcessorExecutionPage;
		Items.PagesCommandBars.CurrentPage = Items.PageCommandBarDataProcessorExecutionPages;
		
		// Delaying the server call until the form state becomes consistent
		AttachIdleHandler("ExecuteDataProcessorServerMethod", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataProcessorServerMethod()
	BackgroundJobCheckExecutionOnClose = True;
	
	ServerCallParameters = New Structure("AdditionalDataProcessorRef, CommandID, TargetObjects");
	ServerCallParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ServerCallParameters.CommandID           = CommandToExecute.ID;
	ServerCallParameters.TargetObjects      = CommandToExecute.TargetObjects;
	
	Result = ExecuteDataProcessorServerMethodAtServer(ServerCallParameters);
	
	If Result.Completed Or Result.ExceptionRaised Then
		ShowDataProcessorsExecutionResult(Result, True);
	Else
		LongActionsClient.InitIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("CheckBackgroundJobExecution", 1, True);
	EndIf;
EndProcedure

&AtServer
Function ExecuteDataProcessorServerMethodAtServer(ServerCallParameters)
	Result = New Structure("Completed, ExceptionRaised, Value", False, False, Undefined);
	
	Try
		If CommonUse.FileInfobase() Then
			Result.Value     = AdditionalReportsAndDataProcessors.ExecuteCommand(ServerCallParameters, Undefined);
			Result.Completed = True;
		Else
			BackgroundJobResult = LongActions.ExecuteInBackground(
				UUID,
				"AdditionalReportsAndDataProcessors.ExecuteCommand", 
				ServerCallParameters, 
				NStr("en = 'Additional reports and data processors: executing a server method of a data processor.'"));
			
			If BackgroundJobResult.JobCompleted Then
				Result.Completed = True;
				Result.Value     = GetFromTempStorage(BackgroundJobResult.StorageAddress);
			Else
				BackgroundJobID             = BackgroundJobResult.JobID;
				BackgroundJobStorageAddress = BackgroundJobResult.StorageAddress;
			EndIf;
		EndIf;
	Except
		Result.ExceptionRaised = True;
		AdditionalReportsAndDataProcessors.WriteError(
			ServerCallParameters.AdditionalDataProcessorRef,
			NStr("en = 'Command: %1. Runtime error: %2'"),
			ServerCallParameters.CommandID,
			Chars.LF + DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Result;
EndFunction

&AtClient
Procedure ShowDataProcessorsExecutionResult(Result, CloseThisForm)
	// Adding notification to the execution result (if required)
	ExecutionResult = ?(Result = Undefined, Undefined, Result.Value);
	If CommandToExecute.ShowNotification Then
		If ExecutionResult = Undefined Then
			ExecutionResult = StandardSubsystemsClientServer.NewExecutionResult();
		EndIf;
		If Not ExecutionResult.Property("NotificationOutput") Then
			ExecutionResult.Insert("NotificationOutput", New Structure("Use, Title, Text, Picture", False));
		EndIf;
		If ExecutionResult.NotificationOutput.Use <> True Then
			ExecutionResult.NotificationOutput.Use   = True;
			ExecutionResult.NotificationOutput.Title = NStr("en = 'Command executed'");
			ExecutionResult.NotificationOutput.Text  = CommandToExecute.Presentation;
		EndIf;
	EndIf;
	
	If Result <> Undefined And Result.ExceptionRaised Then
		// Switching to the command list page.
		Items.Pages.CurrentPage = Items.PageOpenDataProcessor;
		Items.PagesCommandBars.CurrentPage = Items.PageCommandBarPagesOpenDataProcessor;
		// Displaying error message.
		WarningText = NStr("en = 'Cannot execute command: ""%1"".
		|For details, see the event log.'");
		WarningText = StrReplace(WarningText, "%1", CommandToExecute.Presentation);
		ShowMessageBox(, WarningText);
		// Canceling the form closing.
		Return;
	EndIf;
	
	// Updating the owner form.
	If IsObjectForm Then
		Try
			FormOwner.Read();
		Except
			// No action required.
		EndTry;
	EndIf;
	
	// Background job is already completed.
	BackgroundJobCheckExecutionOnClose = False;
	
	// Closing the current form
	If CloseThisForm = True Then
		Close();
	EndIf;
	
	// Displaying execution result.
	StandardSubsystemsClient.ShowExecutionResult(FormOwner, ExecutionResult);
EndProcedure

&AtClient
Procedure CheckBackgroundJobExecution()
	Result = CheckBackgroundJobExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress);
	If Result.Completed Or Result.ExceptionRaised Then
		ShowDataProcessorsExecutionResult(Result, True);
	Else
		LongActionsClient.UpdateIdleHandlerParameters(HandlerParameters);
		AttachIdleHandler("CheckBackgroundJobExecution", HandlerParameters.CurrentInterval, True);
	EndIf;
EndProcedure

&AtServerNoContext
Function CheckBackgroundJobExecutionAtServer(BackgroundJobID, BackgroundJobStorageAddress, Cancel = False)
	Result = New Structure("Completed, ExceptionRaised, Value", False, False, Undefined);
	Try
		If LongActions.JobCompleted(BackgroundJobID) Then
			Result.Completed = True;
			Result.Value     = GetFromTempStorage(BackgroundJobStorageAddress);
		EndIf;
	Except
		Result.ExceptionRaised = True;
	EndTry;
	If Cancel Then
		LongActions.CancelJobExecution(BackgroundJobID);
	EndIf;
	Return Result;
EndFunction

#EndRegion
