////////////////////////////////////////////////////////////////////////////////
// Infobase version update subsystem.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Procedures used for data exchange

// This is a handler for the OnSendDataToSlave event.
//
// Parameters:
// See OnSendDataToSlave() event handler description in the Syntax Assistant.
// 
Procedure OnSendSubsystemVersions(DataItem, ItemSend, Val InitialImageCreating = False) Export
	
	If ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		
		// No overriding for standard processing
		
	ElsIf TypeOf(DataItem) = Type("InformationRegisterRecordSet.SubsystemVersions") Then
		
		If InitialImageCreating Then
			
			If CommonUseCached.DataSeparationEnabled() Then
				
				If CommonUseCached.CanUseSeparatedData() Then
					
					For Each SetRow In DataItem Do
						
						QueryText =
						"SELECT
						|	DataAreaSubsystemVersions.Version AS Version
						|FROM
						|	InformationRegister.DataAreaSubsystemVersions AS DataAreaSubsystemVersions
						|WHERE
						|	DataAreaSubsystemVersions.SubsystemName = &SubsystemName";
						
						Query = New Query;
						Query.SetParameter("SubsystemName", SetRow.SubsystemName);
						Query.Text = QueryText;
						
						Selection = Query.Execute().Select();
						
						If Selection.Next() Then
							
							SetRow.Version = Selection.Version;
							
						Else
							
							SetRow.Version = "";
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
			Else
				
    // When creating an initial image with disabled separation, 
    // register export is performed without additional data processing.
				
			EndIf;
			
		Else
			
		 // Register export is only performed when creating an initial image
			ItemSend = DataItemSend.Ignore;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
