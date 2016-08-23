#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
	DomainAndUserTable = OSUsers();
#ElsIf ThinClient Then
	DomainAndUserTable = New FixedArray (OSUsers());
#EndIf
	
	FillDomainList();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

#EndRegion

#Region DomainTableFormTableItemEventHandlers

&AtClient
Procedure DomainTableOnActivateRow(Item)
	
	CurrentDomainUserList.Clear();
	
	If Item.CurrentData <> Undefined Then
		DomainName = Item.CurrentData.DomainName;
 
		For Each Record In DomainAndUserTable Do
			If Record.DomainName = DomainName Then
				For Each User In Record.Users Do
					DomainUser = CurrentDomainUserList.Add();
					DomainUser.UserName = User;
				EndDo;
				Break;
			EndIf;
		EndDo;
		CurrentDomainUserList.Sort("UserName");
	EndIf;
	
EndProcedure

#EndRegion

#Region UserTableFormTableItemEventHandlers

&AtClient
Procedure DomainUserTableChoice(Item, SelectedRow, Field, StandardProcessing)
	
	ComposeResultAndCloseForm();
	
EndProcedure

#КонецОбласти

#Область ОбработчикиКомандФормы

&AtClient
Procedure Select(Command)
	
	If Items.DomainTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("en = 'Select domain'"));
		Return;
	EndIf;
	DomainName = Items.DomainTable.CurrentData.DomainName;
	
	If Items.DomainUserTable.CurrentData = Undefined Then
		ShowMessageBox(, NStr("en = 'Select domain user.'"));
		Return;
	EndIf;
	UserName = Items.DomainUserTable.CurrentData.UserName;
	
	ComposeResultAndCloseForm();
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtClient
Procedure FillDomainList()
	
	DomainList.Clear();
	
	For Each Record In DomainAndUserTable Do
		Domain = DomainList.Add();
		Domain.DomainName = Record.DomainName;
	EndDo;
	
	DomainList.Sort("DomainName");
	
EndProcedure

&AtClient
Procedure ComposeResultAndCloseForm()
	
	DomainName = Items.DomainTable.CurrentData.DomainName;
	UserName = Items.DomainUserTable.CurrentData.UserName;
 
	ChoiceResult = "\\" + DomainName + "\" + UserName;
	NotifyChoice(ChoiceResult);
	
EndProcedure
 
#EndRegion
