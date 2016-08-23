// Return reference to predefined element "GetSystemEmailAccount" of "EmailAccounts" catalog
//
Function GetSystemEmailAccount() Export
		Return Tasks.GetSystemEmailAccount();
EndFunction

Procedure DirChoiceResult(SelectedFiles, Params) Export 
	
	If SelectedFiles <> Undefined  Then
		For Each File in SelectedFiles Do
			Params.Object[Params.AttributeName] = File;		
		EndDo 		
	EndIf; 	
	
EndProcedure

// Open directory choice dialog and fill given attribute of the object 
//
Procedure DirChoice(Object, AttributeName, Title = Undefined) Export 
	
	DirChoiceDlg = new FileDialog(FileDialogMode.ChooseDirectory);	
	DirChoiceDlg.Title = Title; 
	DirChoiceDlg.Directory = Object[AttributeName];
	Notify = New NotifyDescription("DirChoiceResult",ThisObject, New Structure("Object,AttributeName", Object, AttributeName));
	DirChoiceDlg.Show(Notify);
	
EndProcedure
 
