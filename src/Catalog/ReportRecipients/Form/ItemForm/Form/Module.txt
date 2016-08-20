&AtClient
Procedure SetAvailability()
	Items.Email.Enabled = Object.ByEmail;
	Items.TelegramUserName.Enabled = Object.ByTelegram;
EndProcedure
 
&AtClient
Procedure ByEmailOnChange(Item)
	SetAvailability();
EndProcedure

&AtClient
Procedure ByTelegramOnChange(Item)
	SetAvailability();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetAvailability();
EndProcedure
