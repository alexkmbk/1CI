&AtClient
Procedure PathStartChoice(Item, ChoiceData, StandardProcessing)	
	RepositoryTasksClient.DirChoice(Object, "Path", "Repository path"); 
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		NewLine = RepUsers.Add();	
		NewLine.User = UsersClientServer.CurrentUser();
	Else
		Query = New Query;
		Query.Text = "SELECT
		|	RepUsers.RepUserName,
		|	RepUsers.RepPassword,
		|	RepUsers.User
		|FROM
		|	InformationRegister.RepUsers AS RepUsers
		|WHERE
		|	RepUsers.Repository = &Repository";
		Query.SetParameter("Repository", Object.Ref);
		
		RepUsers.Load(Query.Execute().Unload());		
	EndIf; 
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	IsUsers = False;
	
	RecordSet = InformationRegisters.RepUsers.CreateRecordSet();
	RecordSet.Filter.Repository.Set(Object.Ref);
	For Each Item In RepUsers Do
		// Check if there is at least one user defined for the repository
		If ValueIsFilled(Item.User) Then
			
			NewRecord = RecordSet.Add();
			NewRecord.User = Item.User;
			NewRecord.RepUserName = Item.RepUserName;
			NewRecord.RepPassword = Item.RepPassword;
			NewRecord.Repository = Object.Ref;
			IsUsers = True;
		EndIf; 
	EndDo; 	
	
	If IsUsers Then
		RecordSet.Write(True);	
	Else
		Message("No users is defined for repository """ + Object.Description  + """", MessageStatus.Ordinary); 
		Cancel = True;		
	EndIf; 
	
EndProcedure

&AtClient
Procedure WorkingDirStartChoice(Item, ChoiceData, StandardProcessing)		
	RepositoryTasksClient.DirChoice(Object, "WorkingDir", "Repository path"); 
EndProcedure

&AtClient
Procedure DumpDirStartChoice(Item, ChoiceData, StandardProcessing)
	RepositoryTasksClient.DirChoice(Object, "ConfBackupDir", "Configuration backup directory"); 
EndProcedure

&AtClient
Procedure ConfigurationPathStartChoice(Item, ChoiceData, StandardProcessing)
	RepositoryTasksClient.DirChoice(Object, "DBDir", "Bound database directory"); 
EndProcedure

&AtClient
Procedure TestDBDirStartChoice(Item, ChoiceData, StandardProcessing)
	RepositoryTasksClient.DirChoice(Object, "TestDBDir", "Path to test-database directory"); 
EndProcedure
