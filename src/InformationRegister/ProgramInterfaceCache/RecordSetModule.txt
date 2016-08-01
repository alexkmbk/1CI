#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var VerificationRequired;
Var VerificationTable;

Procedure BeforeWrite(Cancel, Replacing)
	
	// There is no DataExchange.Load property value verification, because the 
	// limitations imposed by the script should not be bypassed by passing
	// True to the Load property (on the side of the script that records to this
	// register).
	//
	// This register cannot be included in any exchanges or data import/export
	// operations if the data area separation is enabled.
	
	VerificationRequired = CommonUseCached.DataSeparationEnabled() And CommonUseCached.CanUseSeparatedData();
	
	If VerificationRequired Then
		
		ReceivingParameters = Undefined;
		If Not AdditionalProperties.Property("ReceivingParameters", ReceivingParameters) Then
			
			Raise NStr("en = 'When data is recorded to the ProgramInterfaceCache information register from the sessions 
                                    |with enabled separators, data receiving parameters for interface cache
                                    |must be passed in additional property of the ReceivingParameters record set.'");
			
		EndIf;
		
		For Each Record In ThisObject Do
			
			Data = CommonUse.PrepareVersionCacheData(
				Record.DataType, ReceivingParameters);
			Record.Data = New ValueStorage(Data);
			
		EndDo;
		
		VerificationTable = ThisObject.Unload();
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	// There is no DataExchange.Load property value verification, because the 
	// limitations imposed by the script should not be bypassed by passing
	// True to the Load property (on the side of the script that records to this
	// register).
	//
	// This register cannot be included in any exchanges or data import/export
	// operations if data area separation is enabled.
	
	If VerificationRequired Then
		
		For Each Record In ThisObject Do
			
			VerificationRows = VerificationTable.FindRows(
				New Structure("ID, DataType", Record.ID, Record.DataType));
			
			If VerificationRows.Count() <> 1 Then
				VerificationError();
			Else
				
				VerificationRow = VerificationRows.Get(0);
				
				CurrentData = CommonUse.ValueToXMLString(Record.Data.Get());
				VerificationData = CommonUse.ValueToXMLString(VerificationRow.Data.Get());
				
				If CurrentData <> VerificationData Then
					VerificationError();
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure VerificationError()
	
	Raise NStr("en = 'The Data resource of the ProgramInterfaceCache information register record cannot be changed 
                            |inside the record transaction from the session with the enabled separation.'");
	
EndProcedure

#EndIf
