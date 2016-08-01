////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
////////////////////////////////////////////////////////////////////////////////

#Region Interface

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for working with infobase data

// Checks whether there are references to the object in the infobase.
//
// Parameters:
//  RefOrRefArray          - AnyRef or
//                         - Array of AnyRef.
//
//  SearchInInternalObjects - Boolean - default value is False.
//                            If it is set to True, the list of search exceptions for
//                            references will not be taken into account.
//
// Returns:
//  Boolean.
//
Function ReferencesToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False) Export
	
	Return CommonUse.ReferencesToObjectFound(RefOrRefArray, SearchInInternalObjects);
	
EndFunction

// Checks whether the documents are posted.
//
// Parameters:
//  Documents - Array - documents to be checked.
//
// Returns:
//  Array - unposted documents from the Documents array.
//
Function CheckDocumentsPosted(Val Documents) Export
	
	Return CommonUse.CheckDocumentsPosted(Documents);
	
EndFunction

// Attempts to post the documents.
//
// Parameters:
// Documents - Array - documents to be posted.
//
// Returns:
// Array - array of Structure with the following fields:
// 					Ref              - unposted document;
// 					ErrorDescription - posting error text.
//
Function PostDocuments(Documents) Export
	
	Return CommonUse.PostDocuments(Documents);
	
EndFunction 

////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for working in the data separation mode

// Sets session separation.
//
// Parameters:
//  Use      - Boolean - flag that shows whether the DataArea separator is used in
//             the session.
//  DataArea - Number - DataArea separator value.
//
Procedure SetSessionSeparation(Val Use, Val DataArea = Undefined) Export
	
	CommonUse.SetSessionSeparation(Use, DataArea);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deletion settings from storages

// Saves settings to the common settings storage.
// 
// Parameters:
//  Corresponds to the CommonSettingsStorage.Save method. 
//  See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey = "", Value, SettingsDescription = Undefined,
	UserName = Undefined, NeedToRefreshCachedValues = False) Export
	
	CommonUse.CommonSettingsStorageSave(
		ObjectKey,
		SettingsKey,
		Value,
		SettingsDescription,
		UserName,
		NeedToRefreshCachedValues);
		
EndProcedure

// Loads settings from the common settings storage.
//
// Parameters:
//  Corresponds to the CommonSettingsStorage.Load method. 
//  See StorageLoad() procedure parameters for details. 
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return CommonUse.CommonSettingsStorageLoad(
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName);
		
EndFunction

// Deletes settings from the common settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Delete method. 
// See StorageDelete() procedure parameters for details. 
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	CommonUse.CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

// Saves the array of user settings to StructureArray. 
// Can be called on client.
// 
// Parameters:
//  StructureArray            - Array - Array of Structure with the following fields:
//                              Object, SettingsItem, Value;
//  NeedToRefreshCachedValues - Boolean - flag that shows whether cached values must
//                              be updated.
//
Procedure CommonSettingsStorageSaveArray(StructureArray, NeedToRefreshCachedValues = False) Export
	
	CommonUse.CommonSettingsStorageSaveArray(StructureArray, NeedToRefreshCachedValues);
	
EndProcedure

// Saves the StructureArray user settings array and updates cached values. 
// Can be called on client.
// 
// Parameters:
// StructureArray - Array - Array of Structure with the following fields:
//                  Object, SettingsItem, Value.
//
Procedure CommonSettingsStorageSaveArrayAndRefreshCachedValues(StructureArray) Export
	
	CommonUse.CommonSettingsStorageSaveArrayAndRefreshCachedValues(StructureArray);
	
EndProcedure

// Saves the settings item to the common settings storage and updates cached values.
// 
// Parameters:
//  Corresponds to the CommonSettingsStorage.Save method. 
//  See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSaveAndRefreshCachedValues(ObjectKey, SettingsKey, Value) Export
	
	CommonUse.CommonSettingsStorageSaveAndRefreshCachedValues(ObjectKey, SettingsKey, Value);
	
EndProcedure

// Saves the settings item to the common settings storage.
// 
// Parameters:
// Corresponds to the CommonSettingsStorage.Save method. 
// See StorageSave() procedure parameters for details. 
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey = "", Value, SettingsDescription = Undefined,
	UserName = Undefined, NeedToRefreshCachedValues = False) Export
	
	CommonUse.SystemSettingsStorageSave(
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure

// Loads the settings item from the common settings storage.
//
// Parameters: 
//  Corresponds to the CommonSettingsStorage.Load method. 
//  See StorageLoad() procedure parameters for details. 
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return CommonUse.SystemSettingsStorageLoad(
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction

// Deletes the settings item from the common settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Delete method. 
// See StorageDelete() procedure parameters for details. 
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	CommonUse.SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

// Saves the settings item from the form data settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Load method. 
// See StorageLoad() procedure parameters for details. 
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey = "", Value, SettingsDescription = Undefined,
	UserName = Undefined, NeedToRefreshCachedValues = False) Export
	
	CommonUse.FormDataSettingsStorageSave(
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure

// Loads the settings item from the form data settings storage.
//
// Parameters:
// Corresponds to the CommonSettingsStorage.Load method. 
// See StorageLoad() procedure parameters for details. 
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return CommonUse.FormDataSettingsStorageLoad(
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction

// Deletes the settings item from the form data settings storage.
//
// Parameters:
//  Corresponds to the CommonSettingsStorage.Delete method. 
//  See StorageDelete() procedure parameters for details. 
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	CommonUse.FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

////////////////////////////////////////////////////////////////////////////////
// Functions for workings with style colors in the client code

// Retrieves a style color by the style item name.
//
// Parameters:
// StyleColorName - String - Style item name.
//
// Returns:
//  Color.
//
Function StyleColor(StyleColorName) Export
	
	Return StyleColors[StyleColorName];
	
EndFunction

// Retrieves a style font by the style item name.
//
// Parameters:
// StyleFontName - String - style item name.
//
// Returns:
//  Font.
//
Function StyleFont(StyleFontName) Export
	
	Return StyleFonts[StyleFontName];
	
EndFunction

#EndRegion
