
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
  // Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
	
	ReadOnly = True;
	
	EmptyRefPresentation = String(TypeOf(Object.EmptyRefValue));
	
	If Not Users.InfobaseUserWithFullAccess(, True)
	 Or Catalogs.MetadataObjectIDs.CannotChangeFullName(Object) Then
		
		Items.FormEnableEditing.Visible = False;
	EndIf;
	
	If CommonUse.IsSubordinateDIBNode() Then
		Items.FormEnableEditing.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

&AtClient
Procedure FullNameOnChange(Item)
	
	FullName = Object.FullName;
	UpdateIDProperties();
	
	If FullName <> Object.FullName Then
		Object.FullName = FullName;
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'The metadata object is not found by the full name:
			           |%1.'"),
			FullName));
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure UpdateIDProperties()
	
	Catalogs.MetadataObjectIDs.UpdateIDProperties(Object);
	
EndProcedure

#EndRegion
