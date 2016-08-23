
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.	
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	MasterNode = Constants.MasterNode.Get();
	
	If Not ValueIsFilled(MasterNode) Then
		Raise NStr("en = Master node is not saved.'");
	EndIf;
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Raise NStr("en = 'Master node is specified.'");
	EndIf;
	
	Items.MessageText.Title = StringFunctionsClientServer.SubstituteParametersInString(
		Items.MessageText.Title, String(MasterNode));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Reconnect(Command)
	
	ReconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	DisconnectAtServer();
	
	Close(New Structure("Cancel", False));
	
EndProcedure

&AtClient
Procedure ExitApp(Command)
	
	Close(New Structure("Cancel", True));
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServerNoContext
Procedure DisconnectAtServer()
	
	MasterNodeManager = Constants.MasterNode.CreateValueManager();
	MasterNodeManager.Value = Undefined;
	InfobaseUpdate.WriteData(MasterNodeManager);
	
	SetInitializationOfAllExistingPredefinedData();
	
	SetInfobasePredefinedDataUpdate(
		PredefinedDataUpdate.Auto);
	
EndProcedure

&AtServerNoContext
Procedure ReconnectAtServer()
	
	MasterNode = Constants.MasterNode.Get();
	
	ExchangePlans.SetMasterNode(MasterNode);
	
EndProcedure

&AtServerNoContext
Procedure SetInitializationOfAllExistingPredefinedData()
	
	MetadataCollection = New Array;
	MetadataCollection.Add(Metadata.Catalogs);
	MetadataCollection.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollection.Add(Metadata.ChartsOfAccounts);
	MetadataCollection.Add(Metadata.ChartsOfCalculationTypes);
	
	Query = New Query;
	QueryText =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	&CurrentTable AS SpecifiedTableAlias
	|WHERE
	|	SpecifiedTableAlias.Predefined";
	
	For Each Collection In MetadataCollection Do
		For Each MetadataObject In Collection Do
			FullName = MetadataObject.FullName();
			Query.Text = StrReplace(QueryText, "&CurrentTable", FullName);
			If Query.Execute().IsEmpty() Then
				Continue;
			EndIf;
			Manager = CommonUse.ObjectManagerByFullName(FullName);
			Manager.SetPredefinedDataUpdate(PredefinedDataUpdate.DontAutoUpdate);
			Manager.SetPredefinedDataUpdate(PredefinedDataUpdate.Auto);
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion
