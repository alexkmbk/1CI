// The following parameter are expected:
//     MasterFormID                  - UUID - ID of the form, through which storage 
//                                     the exchange is performed.
//     CompositionSchemaAddress      - String - address of the temporary composition
//                                     schema storage, for which the settings are
//                                     edited.
//     FilterComposerSettingsAddress - String - address of the temporary storage of
//                                     the composer settings to be edited. 
//     FilterAreaPresentation        - String - presentation for formatting the title.
//
// Returns:
//     Undefined - to cancel editing.
//     String    - address of the temporary storage with new composer settings.
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SelfTest") Then
		Return;
	EndIf;
	
	MasterFormID = Parameters.MasterFormID;
	
	PrefilterComposer = New DataCompositionSettingsComposer;
	PrefilterComposer.Initialize( 
		New DataCompositionAvailableSettingsSource(Parameters.CompositionSchemaAddress) );
		
	FilterComposerSettingsAddress = Parameters.FilterComposerSettingsAddress;
	PrefilterComposer.LoadSettings(GetFromTempStorage(FilterComposerSettingsAddress));
	DeleteFromTempStorage(FilterComposerSettingsAddress);
	
	Title = StrReplace( NStr("en = 'Rule filter ""%1""'"), "%1", Parameters.FilterAreaPresentation) 
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Select(Command)
	
	If Modified Then
		SelectionValue = FilterComposerSettingsAddress();
		NotifyChoice(SelectionValue);
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function FilterComposerSettingsAddress()
	
	Return PutToTempStorage(PrefilterComposer.Settings, MasterFormID)
	
EndFunction

#EndRegion