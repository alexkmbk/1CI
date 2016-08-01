
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersInString(
		NStr("en = 'Quick access to command: %1'"),
		Parameters.CommandPresentation);
	
	For Each UserRow In Parameters.UsersWithQuickAccess Do
		NewRow = ShortListUsers.Add();
		NewRow.User = UserRow.Value;
	EndDo;
	
	FillShortListUserTable();
	
EndProcedure

#EndRegion

#Region AllUsersFormTableItemEventHandlers

&AtClient
Procedure AllUsersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	If TypeOf(DragParameters.Value[0]) = Type("Number") Then
		Return;
	EndIf;
	
	MoveUsers(AllUsers, ShortListUsers, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure AllUsersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region ShortListUsersFormTableItemEventHandlers

&AtClient
Procedure ShortListUsersDrag(Item, DragParameters, StandardProcessing, Row, Field)
	
	If TypeOf(DragParameters.Value[0]) = Type("Number") Then
		Return;
	EndIf;
	
	MoveUsers(ShortListUsers, AllUsers, DragParameters.Value);
	
EndProcedure

&AtClient
Procedure ShortListUsersDragCheck(Item, DragParameters, StandardProcessing, Row, Field)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ClearCommandAccessForAllUsers(Command)
	
	DraggedItemsArray = New Array;
	
	For Each RowDescription In ShortListUsers Do
		DraggedItemsArray.Add(RowDescription);
	EndDo;
	
	MoveUsers(AllUsers, ShortListUsers, DraggedItemsArray);
	
EndProcedure

&AtClient
Procedure ClearCommandAccessForSelectedUsers(Command)
	
	DraggedItemsArray = New Array;
	
	For Each SelectedRow In Items.ShortListUsers.SelectedRows Do
		DraggedItemsArray.Add(Items.ShortListUsers.RowData(SelectedRow));
	EndDo;
	
	MoveUsers(AllUsers, ShortListUsers, DraggedItemsArray);
	
EndProcedure

&AtClient
Procedure SetAccessForAllUsers(Command)
	
	DraggedItemsArray = New Array;
	
	For Each RowDescription In AllUsers Do
		DraggedItemsArray.Add(RowDescription);
	EndDo;
	
	MoveUsers(ShortListUsers, AllUsers, DraggedItemsArray);
	
EndProcedure

&AtClient
Procedure SetCommandForSelectedUsers(Command)
	
	DraggedItemsArray = New Array;
	
	For Each SelectedRow In Items.AllUsers.SelectedRows Do
		DraggedItemsArray.Add(Items.AllUsers.RowData(SelectedRow));
	EndDo;
	
	MoveUsers(ShortListUsers, AllUsers, DraggedItemsArray);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ChoiceResult = New ValueList;
	
	For Each CollectionItem In ShortListUsers Do
		ChoiceResult.Add(CollectionItem.User);
	EndDo;
	
	NotifyChoice(ChoiceResult);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Procedure FillShortListUserTable()
	
	UserArray = ShortListUsers.Unload().UnloadColumn("User");
	
	QueryText = "SELECT
					|	True	AS Used,
					|	Ref	AS User
					|FROM
					|	Catalog.Users
					|WHERE
					|	NOT DeletionMark
					|	AND NOT Ref IN (&UserArray)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.Parameters.Insert("UserArray", UserArray);
	ValueToFormAttribute(Query.Execute().Unload(), "AllUsers");
	
	AllUsers.Sort("User Asc");
	ShortListUsers.Sort("User Asc");
	
EndProcedure

&AtClient
Procedure MoveUsers(Target, Source, DraggedItemsArray)
	
	For Each DraggedItem In DraggedItemsArray Do
		NewUser = Target.Add();
		NewUser.User = DraggedItem.User;
		Source.Delete(DraggedItem);
	EndDo;
	
	Target.Sort("User Asc");
	
EndProcedure

#EndRegion
