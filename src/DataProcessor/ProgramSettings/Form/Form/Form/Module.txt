&AtServer
Function GetSystemEmailAccount()
	Return EmailOperations.SystemAccount(); 
EndFunction

&AtClient
Procedure OpenSystemEmailAccountSettings(Command)
	ShowValue(, GetSystemEmailAccount());
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	UseAdditionalReportsAndDataProcessors = Constants.UseAdditionalReportsAndDataProcessors.Get();
	TelegramBotToken = Constants.TelegramBotToken.Get();
	TelegramBotPassword = Constants.TelegramBotPassword.Get();
EndProcedure


&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure


&AtServer
Procedure OnCloseAtServer()
	Constants.UseAdditionalReportsAndDataProcessors.Set(UseAdditionalReportsAndDataProcessors);
	Constants.TelegramBotToken.Set(TelegramBotToken);
	Constants.TelegramBotPassword.Set(TelegramBotPassword);
EndProcedure


&AtClient
Procedure OpenUsersCatalogClick(Item)
	OpenForm("Catalog.Users.ListForm",,ThisForm);
EndProcedure

