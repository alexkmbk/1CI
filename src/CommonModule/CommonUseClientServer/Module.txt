////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
// Client and server procedures and functions of common use for working with:
// - print forms;
// - files;
// - managed forms;
// - email addresses;
// - dynamic list filters;
// - others.
//
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Generates and displays the message that can relate to a form item.
//
// Parameters
// MessageToUserText - String - message text;
// DataKey           - Any infobase object reference - infobase object reference, to which this
//                     message relates, or a record key;
// Field             - String - form item description;
// DataPath          - String - data path (path to a form attribute);
// Cancel            - Boolean - Output parameter. It is always set to True.
//
// Examples:
//
// 1. Showing the message associated with the object attribute near the managed form field:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"FieldInFormObject",
// 	"Object");
//
// An alternative variant of using in the object form module:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"Object.FieldInFormObject");
//
// 2. Showing the message associated with the form attribute near the managed form field:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"FormAttributeName");
//
// 3. Showing the message associated with infobase object attribute.
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ObjectInfobase, "Responsible");
//
// 4. Showing messages associated with an infobase object attribute by reference.
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), Ref, , , Cancel);
//
// Incorrect using:
// 1. Passing DataKey and DataPath parameters at the same time.
// 2. Passing a value of an illegal type to the DataKey parameter.
// 3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey = Undefined,
		Val Field = "",
		Val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	IsObject = False;
	
#If Not ThinClient And Not WebClient Then
	If DataKey <> Undefined
	 And XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeString = XMLTypeOf(DataKey).TypeName;
		IsObject = Find(ValueTypeString, "Object.") > 0;
	EndIf;
#EndIf
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Adds the error to the error list that will be displayed to the user with the
// ShowErrorsToUser() procedure.
// It is used in FillCheckProcessing procedures.
//
// Parameters:
// Errors           - Undefined - new list will be created,
//                  - value that is set at the first call of this procedure with the Undefined
//                    value.
// ErrorField       - String - value that is specified in the Field property of the UserMessage
//                    object. If you want a row number to be included, it must contain %1.
//                    For example, "Object.Description" or "Object.Users[%1].User".
// SingleErrorText  - String - error message, it is used if there is only one ErrorGroup in the 
//                    collection, for example, NStr("en = 'User is not selected.'").
// ErrorGroup       - Arbitrary - it is used to choose between the single error text and the
//                    several error text, for example, the "Object.Users" name.
//                    If this value is not filled, the single error text should be used.
// LineNumber       - Number - numbering starts with 0, it specifies the row number, that must
//                    be included in the ErrorField string and in the SeveralErrorText
//                    (LineNumber + 1 is substituted).
// SeveralErrorText - String - error message, it is used if several errors with the same 
//                    ErrorGroup property is added, for example, NStr("en = 'User in the row   
//                    %1 is not selected.'").
// LineIndex        - Undefined - matches the LineNumber parameter value.
// Number           - value starts with 0, defines the number of the row to be substituted into
//                    the ErrorField.
//
Procedure AddUserError(Errors, ErrorField, SingleErrorText, ErrorGroup = "", LineNumber = 0, SeveralErrorText = "", LineIndex = Undefined) Export
	
	If Errors = Undefined Then
		Errors = New Structure;
		Errors.Insert("ErrorList", New Array);
		Errors.Insert("ErrorGroups", New Map);
	EndIf;
	
	If Not ValueIsFilled(ErrorGroup) Then
		// If the error group is empty, the single error text must be used
	Else
		If Errors.ErrorGroups[ErrorGroup] = Undefined Then
			// The error group has been used only once, the single error text must be used
			Errors.ErrorGroups.Insert(ErrorGroup, False);
		Else
			// The error group has been used several times, the several error text must be used
			Errors.ErrorGroups.Insert(ErrorGroup, True);
		EndIf;
	EndIf;
	
	Error = New Structure;
	Error.Insert("ErrorField", ErrorField);
	Error.Insert("SingleErrorText", SingleErrorText);
	Error.Insert("ErrorGroup", ErrorGroup);
	Error.Insert("LineNumber", LineNumber );
	Error.Insert("SeveralErrorText", SeveralErrorText);
	Error.Insert("LineIndex", LineIndex);
	
	Errors.ErrorList.Add(Error);
	
EndProcedure

// Displays errors added with the AddUserError() procedure.
//
// Parameters:
// Errors - Undefined - value set in the AddUserError() procedure;
// Cancel - Boolean - it is set to True if errors have been displayed.
//
Procedure ShowErrorsToUser(Errors, Cancel = False) Export
	
	If Errors = Undefined Then
		Return;
	Else
		Cancel = True;
	EndIf;
	
	For Each Error In Errors.ErrorList Do
 
		If Error.LineIndex = Undefined Then

			LineIndex = Error.LineNumber;
		Else
			LineIndex = Error.LineIndex;
		EndIf;
		
		If Errors.ErrorGroups[Error.ErrorGroup] <> True Then
			
			MessageToUser(
				Error.SingleErrorText,
				,
				StrReplace(Error.ErrorField, "%1", Format(LineIndex, "NZ=0; NG=")));
		Else
			MessageToUser(
				StrReplace(Error.SeveralErrorText, "%1", Format(Error.LineNumber + 1, "NZ=0; NG=")),
				,
				StrReplace(Error.ErrorField, "%1", Format(LineIndex, "NZ=0; NG=")));
		EndIf;
	EndDo;
	
EndProcedure
 
// Generates a filling error text for fields and lists.
//
// Parameters:
// FieldKind   - String - can take the following values: Field, Column, List;
// MessageKind - String - can take the following values: FillType, Correctness;
// FieldName   - String - Field name;
// LineNumber  - String, Number - row number;
// ListName    - String - list name;
// MessageText - String - filling error details.
//
// Returns:
// String - filling error text.
//
Function FillingErrorText(FieldKind = "Field", MessageKind = "FillType",
	FieldName = "", LineNumber = "", ListName = "", MessageText = "") Export

	MessageText = "";

	If Upper(FieldKind) = "FIELD" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template = NStr("en = 'The %1 field is not filled.'");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template = NStr("en = 'The %1 field is  filled incorrectly.
								|
								|%4'");
		EndIf;
	ElsIf Upper(FieldKind) = "COLUMN" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template = NStr("en = 'The %1 column in the row %2 of the %3 list is not filled.'");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template = NStr("en = 'The %1 column in the row %2 of the %3 list is filled incorrectly.
								|
								|%4'");
		EndIf;
	ElsIf Upper(FieldKind) = "LIST" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template = NStr("en = 'No rows in the %3 list.'");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template = NStr("en = 'The %3 list is filled incorrectly.
								|
								|%4'");
		EndIf;
	EndIf;
 
	Return StringFunctionsClientServer.SubstituteParametersInString(Template, FieldName, LineNumber, ListName, MessageText);

EndFunction 
 
// Generates a path to the LineNumber row and the AttributeName column of the
// TabularSectionName tabular section to display messages on the form.
// This procedure is for using with the MessageToUser procedure.
// (for passing values to the Field parameter or to the DataPath parameter). 
//
// Parameters:
//  TabularSectionName - String - tabular section name;
//  LineNumber         - Number - tabular section row number;
//  AttributeName      - String - attribute name.
//
// Returns:
// String - Path to a table cell.
//
Function PathToTabularSection(Val TabularSectionName, Val LineNumber, 
	Val AttributeName) Export

	Return TabularSectionName + "[" + Format(LineNumber - 1, "NZ=0; NG=0") + "]." + AttributeName;

EndFunction

// Supplements the destination value table with data from the source value table.
//
// Parameters:
// SourceTable      - ValueTable - rows from this table will be added to the destination table;
// DestinationTable - ValueTable - rows from the source table will be added to this table.
//
Procedure SupplementTable(SourceTable, DestinationTable) Export
	
	For Each SourceTableRow In SourceTable Do
		
		FillPropertyValues(DestinationTable.Add(), SourceTableRow);
		
	EndDo;
	
EndProcedure

// Supplements the Table value table with values from the Array array.
//
// Parameters:
// Table     - ValueTable - table to be supplied with values from the array;
// Array     - Array - array of values for filling the table;
// FieldName - String - name of value table field, to be supplied with values from the array.
//
Procedure SupplementTableFromArray(Table, Array, FieldName) Export

	For Each Value In Array Do
		
		Table.Add()[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Supplements the DestinationArray array with values from the SourceArray array.
//
// Parameters:
//  DestinationArray - Array - array to be supplied with values;
//  SourceArray      - Array - array of values to supply DestinationArray;
//  UniqueValuesOnly - Boolean, optional - if it is True, only values that are not included in
//                     the destination array will be supplied. Such values will be supplied
//                     only once. 
//
Procedure SupplementArray(DestinationArray, SourceArray, UniqueValuesOnly = False) Export

	UniqueValues = New Map;
	
	If UniqueValuesOnly Then
		For Each Value In DestinationArray Do
			UniqueValues.Insert(Value, True);
		EndDo;
	EndIf;
	
	For Each Value In SourceArray Do
		If UniqueValuesOnly And UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		DestinationArray.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo;
	
EndProcedure
 
// Supplies the TargetStructure collection with the values from the SourceStructure collection.
//
// Parameters:
//  TargetStructure - Structure - collection where the new values are added.
//  SourceStructure - Structure - collection where the Key-Value couples are read.
//  WithReplacement - Boolean, Undefined - describes the behavior when the source and target
//                    keys intersect each other.
//                     - True      - replace the target values (the quickest way).
//                     - False     - do not replace the target values (skip).
//                     - Undefined - default value. Raise an exception.
//
Procedure SupplementStructure(TargetStructure, SourceStructure, WithReplacement = Undefined) Export
	
	SearchForKey = (WithReplacement = False Or WithReplacement = Undefined);
	For Each KeyAndValue  In SourceStructure Do
		If SearchForKey And TargetStructure.Property(KeyAndValue.Key) Then
			If WithReplacement = False Then
				Continue;
			Else
				Raise  StringFunctionsClientServer.SubstituteParametersInString(
					NStr("en = 'Source and target structures intersect each other by the %1 key.'"),
					KeyAndValue.Key);
			EndIf
		EndIf;
		TargetStructure.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure  
 
// Removes one conditional appearance item if this is a value list.
// 
// Parameters:
//  ConditionalAppearance - ConditionalAppearance -form item conditional appearance;
//  UserSettingID         - String - setting ID;
//  Value                 - Arbitrary - value to be removed from the appearance list.
//
Procedure RemoveValueListConditionalAppearance(
						ConditionalAppearance,
						Val UserSettingID,
						Val Value) Export
	
	For Each CAItem In ConditionalAppearance.Items Do
		If CAItem.UserSettingID = UserSettingID Then
			If CAItem.Filter.Items.Count() = 0 Then
				Return;
			EndIf;
			ItemFilterList = CAItem.Filter.Items[0];
			If ItemFilterList.RightValue = Undefined Then
				Return;
			EndIf;
			ListItem = ItemFilterList.RightValue.FindByValue(Value);
			If ListItem <> Undefined Then
				ItemFilterList.RightValue.Delete(ListItem);
			EndIf;
			ItemFilterList.RightValue = ItemFilterList.RightValue;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// Deletes all occurrences of the passed value from the array.
//
// Parameters:
//  Array - Array - array, from which the value will be deleted;
//  Value - Arbitrary - value to be deleted from the array.
//
Procedure DeleteAllValueOccurrencesFromArray(Array, Value) Export
	
	CollectionItemCount = Array.Count();
	
	For ReverseIndex = 1 to CollectionItemCount Do
		
		Index = CollectionItemCount - ReverseIndex;
		
		If Array[Index] = Value Then
			
			Array.Delete(Index);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes all occurrences of specified type values.
//
// Parameters:
//  Array - Array - array, from which values will be deleted;
//  Type  – Type - type of values to be deleted from array.
//
Procedure DeleteAllTypeOccurrencesFromArray(Array, Type) Export
	
	CollectionItemCount = Array.Count();
	
	For ReverseIndex = 1 to CollectionItemCount Do
		
		Index = CollectionItemCount - ReverseIndex;
		
		If TypeOf(Array[Index]) = Type Then
			
			Array.Delete(Index);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes one value from the array.
//
// Parameters:
// Array - Array - array, from which the value is be deleted;
// Value - Value - value to be deleted from the array.
//
Procedure DeleteValueFromArray(Array, Value) Export
	
	Index = Array.Find(Value);
	
	If Index <> Undefined Then
		
		Array.Delete(Index);
		
	EndIf;
	
EndProcedure
 
// Deletes duplicate items from the array.
//
// Parameters:
// Array - Array - array of arbitrary values.
//
// Returns:
// Array;
// 
Function CollapseArray(Array) Export
	Result = New  Array;
	SupplementArray(Result, Array, True);
	Return Result;
EndFunction
 
// Fills the destination collection with values from the source collection.
// Objects of the following types can be a destination collection and a source collection:
// ValueTable, ValueTree, ValueList, and other collection types.
//
// Parameters:
//  SourceCollection - ArbitraryCollection - value collection that is a source of filling data;
//  TargetCollection - ArbitraryCollection - value collection that is a target of filling data.
//
Procedure FillPropertyCollection(SourceCollection, TargetCollection) Export
	
	For Each Item In SourceCollection Do
		
		FillPropertyValues(TargetCollection.Add(), Item);
		
	EndDo;
	
EndProcedure

// Gets an array of values containing marked items of the value list.
// 
// Parameters:
//  List - ValueList - value list, with which an array of values will be generated;
// 
// Returns:
//  Array - array of values that contains marked items.
//
Function GetMarkedListItemArray(List) Export
	
	// Returned value of the function
	Array = New Array;
	
	For Each Item In List Do
		
		If Item.Check Then
			
			Array.Add(Item.Value);
			
		EndIf;
		
	EndDo;
	
	Return Array;
EndFunction

// Subtracts one array of elements from another. Returns the result of subtraction.
// 
// Parameters:
//  Array            - Array - array, whose elements are deleted if they are identical to 
//                     elements of SubtractionArray;
//  SubtractionArray - Array - array of elements to be subtracted.
// 
// Returns:
//  Array – the result of subtraction.
//
Function ReduceArray(Array, SubtractionArray) Export
	
	Result = New Array;
	
	For Each Element In Array Do
		
		If SubtractionArray.Find(Element) = Undefined Then
			
			Result.Add(Element);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Converts the job schedule into a structure.
// 
// Parameters:
// Schedule - JobSchedule;
// 
// Returns:
// Structure.
//
Function ScheduleToStructure(Val Schedule) Export
	
	ScheduleValue = Schedule;
	If ScheduleValue = Undefined Then
		ScheduleValue = New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,BeginDate,DayInMonth,WeekDayInMonth," + 
		"WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New Structure(FieldList);
	FillPropertyValues(Result, ScheduleValue, FieldList);
	DetailedDailySchedules = New Array;
	For Each DailySchedule In Schedule.DetailedDailySchedules Do
		DetailedDailySchedules.Add(ScheduleToStructure(DailySchedule));
	EndDo;
	Result.Insert("DetailedDailySchedules", DetailedDailySchedules);
	Return Result;
	
EndFunction		

// Converts the structure into a JobSchedule.
// 
// Parameters:
// ScheduleStructure - Structure;
// 
// Returns:
// JobSchedule.
//
Function StructureToSchedule(Val ScheduleStructure) Export
	
	If ScheduleStructure = Undefined Then
		Return New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,BeginDate,DayInMonth,WeekDayInMonth," + 
		"WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New JobSchedule;
	FillPropertyValues(Result, ScheduleStructure, FieldList);
	DetailedDailySchedules = New Array;
	For Each Schedule In ScheduleStructure.DetailedDailySchedules Do
		 DetailedDailySchedules.Add(StructureToSchedule(Schedule));
	EndDo;
	Result.DetailedDailySchedules = DetailedDailySchedules; 
	Return Result;
	
EndFunction		

// Creates a copy of the passed object.
//
// Parameters:
//  Source - Arbitrary - object to be copied.
//
// Returns:
//  Arbitrary - copy of the object that is passed to the Source parameter.
//
// Note:
//  The function cannot be used for object types (CatalogObject, DocumentObject, and others).
//
Function CopyRecursive(Source) Export
	
	Var Destination;
	
	SourceType = TypeOf(Source);
	If SourceType = Type("Structure") Then
		Destination = CopyStructure(Source);
	ElsIf SourceType = Type("Map") Then
		Destination = CopyMap(Source);
	ElsIf SourceType = Type("Array") Then
		Destination = CopyArray(Source);
	ElsIf SourceType = Type("ValueList") Then
		Destination = CopyValueList(Source);
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	ElsIf SourceType = Type("ValueTable") Then
		Destination = Source.Copy();
	#EndIf
	Else
		Destination = Source;
	EndIf;
	
	Return Destination;
	
EndFunction

// Creates a copy of the value of the Structure type.
// 
// Parameters:
//  SourceStructure – Structure – structure to be copied.
// 
// Returns:
//  Structure - copy of the source structure.
//
Function CopyStructure(SourceStructure) Export
	
	ResultStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultStructure;
	
EndFunction

// Creates a copy of the value of the Map type.
// 
// Parameters:
// SourceMap – Map - map to be copied.
// 
// Returns:
// Map - copy of the source map.
//
Function CopyMap(SourceMap) Export
	
	ResultMap= New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultMap;

EndFunction

// Creates a copy of the value of the Array type.
// 
// Parameters:
// SourceArray – Array - array to be copied.
// 
// Returns:
// Array - copy of the source array.
//
Function CopyArray(SourceArray) Export
	
	ResultArray = New Array;
	
	For Each Item In SourceArray Do
		ResultArray.Add(CopyRecursive(Item));
	EndDo;
	
	Return ResultArray;
	
EndFunction

// Creates a copy of the value of the ValueList type.
// 
// Parameters:
// SourceList – ValueList - value list to be copied.
// 
// Returns:
// ValueList - copy of the source value list.
//
Function CopyValueList(SourceList) Export
	
	ResultList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultList.Add(
			CopyRecursive(ListItem.Value), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultList;
	
EndFunction
	
// Compares value list items or array elements by values.
Function ValueListsEqual(List1, List2) Export
	
	EqualLists = True;
	
	For Each ListItem1 In List1 Do
		If FindInList(List2, ListItem1) = Undefined Then
			EqualLists = False;
			Break;
		EndIf;
	EndDo;
	
	If EqualLists Then
		For Each ListItem2 In List2 Do
			If FindInList(List1, ListItem2) = Undefined Then
				EqualLists = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return EqualLists;
	
EndFunction 

// Creates an array and places the passed value in it.
Function ValueInArray(Value) Export
	
	Array = New Array;
	Array.Add(Value);
	
	Return Array;
	
EndFunction

// Manages the state of the spreadsheet document field.
//
// Parameters:
//  SpreadsheetDocumentField – FormField – form field of the SpreadsheetDocumentField type,
//                             whose state will be set.
//  State                    – String – state.
// 
Procedure SetSpreadsheetDocumentFieldState(SpreadsheetDocumentField, State = "DontUse") Export
	
	If TypeOf(SpreadsheetDocumentField) = Type("FormField") 
		And SpreadsheetDocumentField.Type = FormFieldType.SpreadsheetDocumentField Then
		StatePresentation = SpreadsheetDocumentField.StatePresentation;
		If Upper(State) = "DONTUSE" Then
			StatePresentation.Visible = False;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
			StatePresentation.Picture = New Picture;
			StatePresentation.Text = "";
		ElsIf Upper(State) = "IRRELEVANCE" Then
			StatePresentation.Visible = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture = New Picture;
			StatePresentation.Text = NStr("en = 'The report has not been generated. Click Generate to get the report.'");
		ElsIf Upper(State) = "REPORTCREATION" Then 
			StatePresentation.Visible = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture = PictureLib.LongAction48;
			StatePresentation.Text = NStr("en = Generating the report...'");
		Else
			Raise(NStr("en = 'Invalid parameter value (parameter number 2)'"));
		EndIf;
	Else
		Raise(NStr("en = 'Invalid parameter value (parameter number 1)'"));
	EndIf;
	
EndProcedure

// Gets the configuration version number without the assembly number
// 
// Parameters:
//  Version - String - configuration version in the following format: RR.SS.VV.BB,
//            where AA is the assembly number to be removed.
// 
// Returns:
//  String - configuration version number without the assembly number in the following format:
//  RR.SS.VV
//
Function ConfigurationVersionWithoutAssemblyNumber(Val Version) Export
	
	Array = StringFunctionsClientServer.SplitStringIntoSubstringArray(Version, ".");
	
	If Array.Count() < 3 Then
		Return Version;
	EndIf;
	
	Result = "[Revision].[Subrevision].[Version]";
	Result = StrReplace(Result, "[Revision]", Array[0]);
	Result = StrReplace(Result, "[Subrevision]", Array[1]);
	Result = StrReplace(Result, "[Version]", Array[2]);
	
	Return Result;
EndFunction

// Compare two version strings.
//
// Parameters
//  VersionString1 – String – version number in the following format EE.{S|SS}.RR.AA
//  VersionString2 – String – second version number to be compared.
//
// Returns:
//  Number – greater than 0 if VersionString1 > VersionString2; 0 if the versions are equal.
//
Function CompareVersions(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0.0", VersionString2);
	Version1 = StringFunctionsClientServer.SplitStringIntoSubstringArray(String1, ".");
	If Version1.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
		 NStr("en = 'Invalid version string format: %1'"), VersionString1);
	EndIf;
	Version2 = StringFunctionsClientServer.SplitStringIntoSubstringArray(String2, ".");
	If Version2.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersInString(
	 NStr("en = 'Invalid version string format: %1'"), VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 to 3 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction
 
// Retrieves a string with the structure keys separated by the specified value.
//
// Parameters:
//  Structure - Structure - structure whose keys are converted to a string.
//  Separator - String - separator that is inserted to the string between the structure keys.
//
// Returns:
// String - string with the separated structure keys
//
Function StructureKeysToString(Structure, Separator = ",") Export
	
	Result = "";
	
	For Each Item In Structure Do
		
		SeparatorChar = ?(IsBlankString(Result), "",  Separator);
		
		Result = Result + SeparatorChar + Item.Key;
		
	EndDo;
	
	Return Result;
	
EndFunction
 
// Obsolete. It is recommended that you use CommonUse.CommonModule or CommonUseClient.CommonModule.
// Returns a reference to the common module by the name.
//
// Parameters:
//  Name          - String - common module name, for example:
//                 CommonUse,
//                 CommonUseClient.
//
// Returns:
//  CommonModule.
//
Function CommonModule(Name) Export
 
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	Module = CommonUse.CommonModule(Name);
#Else
	Module = CommonUseClient.CommonModule(Name);
#EndIf
 
 Return Module;
 
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for working with files.

// Deletes all files in the specified directory.
//
// Parameters:
// Path - String - the full path to the directory, whose
// files will be deleted.
//
Procedure DeleteDirectoryWithFiles(Path) Export
	
	Directory = New File(Path);
	
	If Directory.Exist() Then
		DeleteFiles(Path);
	EndIf;
	
EndProcedure

// Adds the final separator character to the passed directory path if it is missing. 
//
// Parameters:
//  DirectoryPath - String - directory path;
//
// Returns:
//  String - directory path with the final separator character.
//
// Examples:
// Result = AddFinalPathSeparator("C:\My directory");
// Returns "C:\My directory\"
// Result = AddFinalPathSeparator("C:\My directory\"); 
// Returns "C:\My directory\"
// Result = AddFinalPathSeparator("%APPDATA%"); 
// Returns "%APPDATA%\"
//
Function AddFinalPathSeparator(Val DirectoryPath) Export
	
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
 	CharToAdd = GetPathSeparator();

	
	If Right(DirectoryPath, 1) = CharToAdd Then
		Return DirectoryPath;
	Else 
		Return DirectoryPath + CharToAdd;
	EndIf;
EndFunction 

// Generates a full file name from the directory name and the file name.
//
// Parameters
//  DirectoryName – String - path to the directory with the file on the hard disk;
//  FileName      – String - file name without the directory name.
//
// Returns:
//  String – the full file name with the directory name.
//
Function GetFullFileName(Val DirectoryName, Val FileName) Export

	If Not IsBlankString(FileName) Then
		
		Slash = "";
		If (Right(DirectoryName, 1) <> "\") And (Right(DirectoryName, 1) <> "/") Then
			Slash = ?(Find(DirectoryName, "\") = 0, "/", "\");
		EndIf;
		
		Return DirectoryName + Slash + FileName;
		
	Else
		
		Return DirectoryName;
		
	EndIf;

EndFunction

// Splits the full file name into components.
//
// Parameters
// FullFileName – String - full file path.
// IsFolder     – Boolean - a flag that shows whether a full directory name is being split
//               (not a file name).
//
// Returns:
//  Structure – file name, split into components (like File object properties):
// 	            FullName  - contains the full file path, it is equal to the FullFileName input 
//                           parameter;
// 	            Path      - contains the path to the directory, where the file is placed;
// 	            Name      - contains the file name with the extension but without the file
//                           path;
// 	            Extension - contains the file extension;
// 	            BaseName  - contains the file name without the extension and the path;
// Example: if FullFileName = "c:\temp\test.txt" then the structure is filled in the following
// way:
// 			FullName: "c:\temp\test.txt"
// 			Path: "c:\temp\"
// 			Name: "test.txt"
// 			Extension: ".txt"
// 			BaseName: "test"
//
Function SplitFullFileName(Val FullFileName, IsFolder = False) Export
	
	FileNameStructure = New Structure("FullName,Path,Name,Extension,BaseName");
	
	// Removing the final slash from the full file name and recording the resulted full name to the structure
	If IsFolder And (Right(FullFileName, 1) = "/" Or Right(FullFileName, 1) = "\") Then
		If IsFolder Then
			FullFileName = Mid(FullFileName, 1, StrLen(FullFileName) - 1);
		Else
			// If the file path ends with slash, then the file has no name
			FileNameStructure.Insert("FullName", FullFileName); 
			FileNameStructure.Insert("Path", FullFileName); 
			FileNameStructure.Insert("Name", ""); 
			FileNameStructure.Insert("Extension", ""); 
			FileNameStructure.Insert("BaseName", ""); 
			Return FileNameStructure;
		EndIf;
	EndIf;
	FileNameStructure.Insert("FullName", FullFileName); 
	
	// If the full file name is empty, then all other structure parameters have to be returned empty too
	If StrLen(FullFileName) = 0 Then 
		FileNameStructure.Insert("Path", ""); 
		FileNameStructure.Insert("Name", ""); 
		FileNameStructure.Insert("Extension", ""); 
		FileNameStructure.Insert("BaseName", ""); 
		Return FileNameStructure;
	EndIf;
	
	// Extracting the file path and the file name									 
	If Find(FullFileName, "/") > 0 Then
		SeparatorPosition = StringFunctionsClientServer.FindCharFromEnd(FullFileName, "/");
	ElsIf Find(FullFileName, "\") > 0 Then
		SeparatorPosition = StringFunctionsClientServer.FindCharFromEnd(FullFileName, "\");
	Else
		SeparatorPosition = 0;
	EndIf;
	FileNameStructure.Insert("Path", Left(FullFileName, SeparatorPosition)); 
	FileNameStructure.Insert("Name", Mid(FullFileName, SeparatorPosition + 1));
	
	// Extracting the file extension (folders have no extensions)
	If IsFolder Then
		FileNameStructure.Insert("Extension", "");
		FileNameStructure.Insert("BaseName", FileNameStructure.Name);
	Else
DotPosition = StringFunctionsClientServer.FindCharFromEnd(FileNameStructure.Name, ".");
		If DotPosition = 0 Then
			FileNameStructure.Insert("Extension", "");
			FileNameStructure.Insert("BaseName", FileNameStructure.Name);
		Else
			FileNameStructure.Insert("Extension", Mid(FileNameStructure.Name, DotPosition));
			FileNameStructure.Insert("BaseName", Left(FileNameStructure.Name, DotPosition - 1));
		EndIf;
	EndIf;
	
	Return FileNameStructure;
	
EndFunction
 
// Parses the URI string into parts and returns them as a structure.
// The following normalizations are described based on RFC 3986.
//
// Parameters:
// URLString - String - link to the resource in the following format:
//             <schema>://<username>:<password>@<domain>:<port>/<path>?<query_string>#<fragment_id>
//
// Returns:
// Structure      - composite part of the URI according to the format:
// * Schema       - String.
// * Username     - String.
// * Password     - String.
// * ServerName   - String - <domain>:<port> part of the input parameter.
// * Domain       - String
// * Port         - String
// * PathAtServer - String - <path>?<query_string>#<fragment_id> part of the input parameter
//
Function URIStructure(Val URLString) Export
	
	URLString = TrimAll(URLString);
	
	// Schema
	Schema = "";
	Position = Find(URLString, "://");
	If Position > 0 Then
		Schema = Lower(Left(URLString, Position - 1));
		URLString = Mid(URLString, Position + 3);
	EndIf;

	// Connection string and path on server
	ConnectionString = URLString;
	PathAtServer = "";
	Position = Find(ConnectionString, "/");
	If Position > 0 Then
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
		
	// User details and server name
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = Find(ConnectionString, "@");
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// Username and password
	Login = AuthorizationString;
	Password = "";
	Position = Find(AuthorizationString, ":");
	If Position > 0 Then
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// Domain and port
	Domain = ServerName;
	Port = "";
	Position = Find(ServerName, ":");
	If Position > 0 Then
		Domain = Left(ServerName, Position - 1);
		Port   = Mid(ServerName, Position + 1);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", ServerName);
	Result.Insert("Domain", Domain);
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", PathAtServer);
	
	Return Result;
	
EndFunction
 
 // Parses the string into an array, using dot (.), slash mark (/), and backslash (\) as
 // separators.
Function ParseStringByDotsAndSlashes(Val String) Export
	
	Var CurrentPosition;
	
	Particles = New Array;
	
	StartIndex = 1;
	
	For CurrentPosition =  1 to StrLen(String) Do
		CurrentChar = Mid(String, CurrentPosition, 1);
		If CurrentChar = "." Or CurrentChar = "/" Or CurrentChar = "\" Then
			CurrentParticle = Mid(String, StartIndex, CurrentPosition - StartIndex);
			StartIndex = CurrentPosition + 1;
			Particles.Add(CurrentParticle);
		EndIf;
	EndDo;
	
	If StartIndex <> CurrentPosition Then
		CurrentParticle = Mid(String, StartIndex, CurrentPosition - StartIndex);
		Particles.Add(CurrentParticle);
	EndIf;
	
	Return Particles;
	
EndFunction
	 
// Extracts the extension (a set of characters after the last dot) from the file name.
//
// Parameters:
//  FileName - String - file name with or without directory name.
//
// Returns:
//  String - file extension.
//
Function GetFileNameExtension(Val FileName)  Export
	
	Extension = "";
	
	CharPosition = StrLen(FileName);
	While CharPosition >= 1 Do
		
		If Mid(FileName, CharPosition, 1) = "." Then
			
			Extension = Mid(FileName, CharPosition + 1);
			Break;
		EndIf;
		
		CharPosition = CharPosition - 1;
	EndDo;

	Return Extension;
	
EndFunction
 
// Converts the file extension to lower case without dots.
//
// Parameters:
//  Extension - String - extension to be converted.
//
// Returns:
//  String.
//
Function ExtensionWithoutDot(Val Extension) Export
	
	Extension = Lower(TrimAll(Extension));
	
	If Mid(Extension, 1, 1) = "." Then
		Extension = Mid(Extension, 2);
	EndIf;
	
	Return Extension;
	
EndFunction
 
// Returns path separator of the file system.
// 
// Parameters:
// Platform - Undefined -
//             On the client - path separator of the client file system.
//             On the server - path separator of the server file system. 
//          - PlatformType - file system path separator of the specified platform type.
//
Function PathSeparator(Platform = Undefined) Export
	
	If Platform = Undefined Then
		
	#If ThickClientOrdinaryApplication Or ExternalConnection Then
		SystemInfo = New SystemInfo;
		Platform = SystemInfo.PlatformType;
	#ElsIf Client Then
		Platform = CommonUseClientCached.ClientPlatformType();
	#Else
		Platform = CommonUseCached.ServerPlatformType();
	#EndIf
	
	EndIf;
	
	If Platform = PlatformType.Windows_x86
	 Or Platform = PlatformType.Windows_x86_64 Then
		
		Return "\";
	Else
		Return "/";
	EndIf;
	
EndFunction
 
// Returns the file name with extension.

// If the extension is not filled, the dot (.) is not added.
//
// Parameters:
//  BaseName   - String.
//  Extension - String.
//
// Returns:
//  String.
//
Function GetNameWithExtension(BaseName, Extension) Export
	
	NameWithExtension = BaseName;
	
	If Extension <> "" Then
		NameWithExtension = NameWithExtension + "." + Extension;
	EndIf;
	
	Return NameWithExtension;
	
EndFunction 
 
// Returns a string of characters prohibited in file names in the supported operating systems.
//
// Returns:
//  String - string of prohibited characters.
//
Function GetProhibitedCharsInFileName() Export

	ProhibitedChars = """/\[]:;|=?*<>";
	Return ProhibitedChars;

EndFunction

// Checks whether the file name has prohibited characters. 
// 
// Parameters
//  FileName - String.
// 
// Returns:
//  Array - array of the prohibited characters that are found in the file name.
//  If there are no prohibited characters, an empty array is returned.
//
Function FindProhibitedCharsInFileName(FileName) Export

	ProhibitedChars = GetProhibitedCharsInFileName();
	
	FoundProhibitedCharArray = New Array;
	
	For CharPosition = 1 to StrLen(ProhibitedChars) Do
		CharToCheck = Mid(ProhibitedChars,CharPosition,1);
		If Find(FileName,CharToCheck) <> 0 Then
			FoundProhibitedCharArray.Add(CharToCheck);
		EndIf;
	EndDo;
	
	Return FoundProhibitedCharArray;

EndFunction

// Replaces prohibited characters in the file name.
//
// Parameters
//  FileName    - String - initial file name;
//  ReplaceWith - String - string that will be substituted for the prohibited characters.
//
// Returns:
// String - resulting file name.
//
Function ReplaceProhibitedCharsInFileName(FileName, ReplaceWith = " ") Export
 
	Result =  FileName;
	FoundProhibitedCharArray = FindProhibitedCharsInFileName(Result);
	For Each ProhibitedChar In FoundProhibitedCharArray Do
		Result = StrReplace(Result, ProhibitedChar, ReplaceWith);
	EndDo;
	
	Return Result;

EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for working with email addresses.

// Splits the string with email addresses according to the RFC 5322 standard with the following
// restrictions:
//
// 1. It is allowed only letters, digits, underscore (_) , en dash (-), dot (.), and at sigh
//    (@) in the address.
// 2. Bracket characters <>[]() are allowed but will be replaced with the space character.
// 3. Groups are prohibited.
//
// Parameters:
//  String - String - string that contains email addresses (mailbox-list).
//
// Returns:
//  Array - array of the address structures with the following fields:
//           Alias            - String - address presentation;
//           Address          - String - found email address that meet the requirements;
//                              If a text that looks like an address is found, but it does not
//                              meet the standard requirements, the text is interpreted as an
//                              Alias field value.
//           ErrorDescription - String - Error text presentation or an empty string if there
//                              are no errors.
//
Function EmailsFromString(Val String) Export
	
	Result = New Array;
	
	// Replacing brackets with the space characters.
	BracketChars = "<>()[]";
	String = ReplaceCharsInStringWithSpaces(String, BracketChars);
	
	// Adjusting splitters to one kind
	String = StrReplace(String, ",", ";");
	
	// Parsing the mailbox-list into mailboxes
	AddressArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(String, ";", True);
	
	// Symbols that are allowed for alias (display-name)
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "0123456789";
	AdditionalChars = "._-";
	
	// Extracting the alias (display-name) and the address (addr-spec) from the address string (Mailbox)
	For Each AddressString In AddressArray Do
		
		Alias = "";
		Address = "";
		ErrorDescription = "";
		
		If StrOccurrenceCount(AddressString, "@") <> 1 Then
			Alias = AddressString;
		Else
			// Everything that does not have email address format is interpreted as a alias
			For Each Substring In StringFunctionsClientServer.SplitStringIntoSubstringArray(AddressString, " ") Do
				If IsBlankString(Address) And EmailAddressMeetsRequirements(Substring) Then
					Address = Substring;
				Else
					Alias = Alias + " " + Substring;
				EndIf;
			EndDo;
		EndIf;
		
		Alias = TrimAll(Alias);
		
		// Checks
		HasProhibitedCharsInAlias = Not StringContainsAllowedCharsOnly(Lower(Alias), Letters + Digits + AdditionalChars);
		AddressDefined = Not IsBlankString(Address);
		StringContainsEmail = Find(AddressString, "@") > 0;
		
		If AddressDefined Then 
			If HasProhibitedCharsInAlias Then
				ErrorDescription = NStr("en = 'The presentation contains prohibited characters'");
			EndIf;
		Else
			If StringContainsEmail Then 
				ErrorDescription = NStr("en = 'The email address contains errors'");
			Else
				ErrorDescription = NStr("en = 'The string does not contain email addresses'");
			EndIf;
		EndIf;	
		
		AddressStructure = New Structure("Alias,Address,ErrorDescription", Alias, Address, ErrorDescription);
		Result.Add(AddressStructure);
	EndDo;
	
	Return Result;	
	
EndFunction

// Checks whether the email address meets the RFC 5321, RFC 5322,
// RFC 5335, RFC 5336, and RFC 3696 standard requirements.
// In addition, the function limits special symbol usage.
// 
// Parameters:
// Address - String - email to be validated.
//
// Returns:
// Boolean - True if there are no errors.
//
Function EmailAddressMeetsRequirements(Val Address, AllowLocalAddresses = False) Export
	
	// Symbols that are allowed in email addresses
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "0123456789";
	SpecChars = ".@_-";
	
	// Checking all special symbol combinations
	If StrLen(SpecChars) > 1 Then
		For Position1 = 1 to StrLen(SpecChars)-1 Do
			Char1 = Mid(SpecChars, Position1, 1);
			For Position2 = Position1 + 1 to StrLen(SpecChars) Do
				Char2 = Mid(SpecChars, Position2, 1);
				Combination1 = Char1 + Char2;
				Combination2 = Char2 + Char1;
				If Find(Address, Combination1) > 0 Or Find(Address, Combination2) > 0 Then
					Return False;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	// Checking the at sing (@)
	If StrOccurrenceCount(Address, "@") <> 1 Then
		Return False;
	EndIf;
	 
	// Checking two dots in succession
	If Find(Address, "..") > 0 Then
		Return False;
	EndIf;
	
	// Adjusting the address string to the lower case
	Address = Lower(Address);
	
	// Check allowed symbols
	If Not StringContainsAllowedCharsOnly(Address, Letters + Digits + SpecChars) Then
		Return False;
	EndIf;
	
	// Splitting the address into a local-part and a domain
	Position = Find(Address,"@");
	LocalName = Left(Address, Position - 1);
	Domain = Mid(Address, Position + 1);
	
// Checking whether LocalName and Domain are filled and their lengths meet the requirements
	If IsBlankString(LocalName)
	 	Or IsBlankString(Domain)
		Or StrLen(LocalName) > 64
		Or StrLen(Domain) > 255 Then
		
		Return False;
	EndIf;
	
	// Checking whether there are any special characters at the beginning and at the end of 
	// LocalName and Domain. 
	If HasCharsLeftRight(LocalName, SpecChars) Or HasCharsLeftRight(Domain, SpecChars) Then
		Return False;
	EndIf;
	
	// Domain has to contain at least one dot
	If Not AllowLocalAddresses And Find(Domain,".") = 0 Then
		Return False;
	EndIf;
	
	// Domain has to contain no underscores (_)
	If Find(Domain,"_") > 0 Then
		Return False;
	EndIf;
	
	// Extracting a top-level domain (TLD) from the domain name 
	TLD = Domain;
	Position = Find(TLD,".");
	While Position > 0 Do
		TLD = Mid(TLD, Position + 1);
		Position = Find(TLD,".");
	EndDo;
	
	// Checking TLD (at least 2 characters, letters only)
	Return AllowLocalAddresses Or StrLen(TLD) >= 2 And StringContainsAllowedCharsOnly(TLD,Letters);
	
EndFunction

// Checks correctness of the passed string with email addresses.
//
// String format:
//  Z = UserName|[User Name] [<]user@mail_server[>], String = Z[<splitter*>Z]
// 
//  Note: splitter* is any address splitter.
//
// Parameters:
//  EmailAddressString - String - correct string with email addresses.
//
// Returns:
//  Structure
//  State - Boolean - flag that shows whether conversion completed successfully.
//          If conversion completed successfully it contains Value, which is an array of
//          structures with the following keys:
//           Address      - recipient email address;
//           Presentation - recipient name.
//          If conversion failed it contains ErrorMessage - String.
//
// IMPORTANT: The function returns an array of structures, where one field (any field)
//            can be empty. It can be used by various subsystems for mapping user names to
//            email addresses. Therefore it is necessary to check before sending whether email
//            address is filled.
//
Function SplitStringWithEmailAddresses(Val EmailAddressString, RaiseException = True) Export
	
	Result = New Array;
	
	ProhibitedChars = "!#$%^&*()+`~|\/=";
	
	ProhibitedCharsMessage = NStr("en = 'There is a prohibited character %1 in the email address %2'");
	MessageInvalidEmailFormat = NStr("en = 'Incorrect email address %1'");
	
	SubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailAddressString,";",True);
	SubstringArrayToProcess = New Array;
	
	For Each ArrayElement In SubstringArray Do
		If Find(ArrayElement,",") > 0 Then
			AdditionalSubstringArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailAddressString);
			For Each AdditionalArrayElement In AdditionalSubstringArray Do
				SubstringArrayToProcess.Add(AdditionalArrayElement);
			EndDo;
		Else
			SubstringArrayToProcess.Add(ArrayElement);
		EndIf;
	EndDo;
	
	For Each AddressString In SubstringArrayToProcess Do
		
		Index = 1;              // Number of processed character.
		Accumulator = "";       // Character accumulator. After the end of analysis, it passes its 
		                        // value to the full name or to the mail address.
		AddresseeFullName = ""; // Variable that accumulates the addressee name.
		EmailAddress = "";      // Variable that accumulates the email address.
		// 1 - Generating the full name: any allowed characters of the addressee name are expected.
		// 2 - Generating the mail address: any allowed characters of the email address are
		//     expected.
		// 3 - Ending mail address generation: a splitter character or a space character are
		//     expected. 
		ParsingStage = 1; 
		
		While Index <= StrLen(AddressString) Do
			
			Char = Mid(AddressString, Index, 1);
			
			If Char = " " Then
				Index = ?((SkipChars(AddressString, Index, " ") - 1) > Index,
				SkipChars(AddressString, Index, " ") - 1,
				Index);
				If ParsingStage = 1 Then
					AddresseeFullName = AddresseeFullName + Accumulator + " ";
				ElsIf ParsingStage = 2 Then
					EmailAddress = Accumulator;
					ParsingStage = 3;
				EndIf;
				Accumulator = "";
			ElsIf Char = "@" Then
				If ParsingStage = 1 Then
					ParsingStage = 2;
					
					For PCSearchIndex = 1 to StrLen(Accumulator) Do
						If Find(ProhibitedChars, Mid(Accumulator, PCSearchIndex, 1)) > 0 And RaiseException Then
							Raise StringFunctionsClientServer.SubstituteParametersInString(
							 ProhibitedCharsMessage,Mid(Accumulator, PCSearchIndex, 1),AddressString);
						EndIf;
					EndDo;
					
					Accumulator = Accumulator + Char;
				ElsIf ParsingStage = 2 And RaiseException Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
					 MessageInvalidEmailFormat,AddressString);
				ElsIf ParsingStage = 3 And RaiseException Then
					Raise StringFunctionsClientServer.SubstituteParametersInString(
					 MessageInvalidEmailFormat,AddressString);
				EndIf;
			Else
				If ParsingStage = 2 Or ParsingStage = 3 Then
					If Find(ProhibitedChars, Char) > 0 And RaiseException Then
						Raise StringFunctionsClientServer.SubstituteParametersInString(
						 ProhibitedCharsMessage,Char,AddressString);
					EndIf;
				EndIf;
				
				Accumulator = Accumulator + Char;
			EndIf;
			
			Index = Index + 1;
		EndDo;
		
		If ParsingStage = 1 Then
			AddresseeFullName = AddresseeFullName + Accumulator;
		ElsIf ParsingStage = 2 Then
			EmailAddress = Accumulator;
		EndIf;
		
		If IsBlankString(EmailAddress) And (Not IsBlankString(AddresseeFullName)) And RaiseException Then
			Raise StringFunctionsClientServer.SubstituteParametersInString(
			 MessageInvalidEmailFormat,AddresseeFullName);
		ElsIf StrOccurrenceCount(EmailAddress,"@") <> 1 And RaiseException Then 
			Raise StringFunctionsClientServer.SubstituteParametersInString(
			 MessageInvalidEmailFormat,EmailAddress);
		EndIf;
		
		If Not (IsBlankString(AddresseeFullName) And IsBlankString(EmailAddress)) Then
			Result.Add(CheckAndPrepareEmailAddress(AddresseeFullName, EmailAddress));
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Functions for working with dynamic list filters and parameters.

// Searches for the item and the group of the dynamic list filter by the passed field name or
// presentation.
// Parameters:
//  SearchArea   - container with items and groups of the filter, for example
//                 List.Filter or a group in the filter;
//  FieldName    - String - data composition field name (is not used for groups);
//  Presentation - String - data composition field presentation;
//
Function FindFilterItemsAndGroups(Val SearchArea,
									Val FieldName = Undefined,
									Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	Return ItemArray;
	
EndFunction

// Adds filter groups to ItemCollection.
// Parameters:
//  ItemCollection - container with items and groups of the filter, for example
//                   List.Filter or a group in the filter;
//  GroupType      - DataCompositionFilterItemsGroupType - group type; 
//  Presentation   - String - group presentation.
//
Function CreateFilterItemGroup(Val ItemCollection, Presentation, GroupType) Export
	

	If TypeOf(ItemCollection) = Type("DataCompositionFilterItemGroup") Then

		ItemCollection = ItemCollection.Items;
	EndIf;
	
	FilterItemGroup = FindFilterItemByPresentation(ItemCollection, Presentation);
	If FilterItemGroup = Undefined Then
		FilterItemGroup = ItemCollection.Add(Type("DataCompositionFilterItemGroup"));
	Else
		FilterItemGroup.Items.Clear();
	EndIf;
	
	FilterItemGroup.Presentation = Presentation;
	FilterItemGroup.Application = DataCompositionFilterApplicationType.Items;
	FilterItemGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItemGroup.GroupType = GroupType;
	FilterItemGroup.Use = True;
	
	Return FilterItemGroup;
	
EndFunction

// Adds the composition item into the composition item container.
//
// Parameters:
// ItemCollection - container with items and groups of the filter, for example
//                  List.Filter or a group in the filter;
// FieldName      - String - data composition field name. Must be filled.
// ComparisonType - DataCompositionComparisonType - comparison type; 
// RightValue     - Arbitrary - value to be compared; 
// Presentation   - String - data composition item presentation;
// Use            - Boolean - item usage;
// ViewMode       - DataCompositionSettingsItemViewMode - view mode.
// UserSettingID  - String - see DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Function AddCompositionItem(AreaToAdd,
									Val FieldName,
									Val ComparisonType,
									Val RightValue = Undefined,
									Val Presentation = Undefined,
									Val Use = Undefined,
									Val ViewMode = Undefined,
									Val UserSettingID = Undefined) Export
	
	Item = AreaToAdd.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
 
	// Important: The ID must be set up in the final stage of the item customization or it will
	// be copied to the user settings in a half-filled condition.
	If UserSettingID  <> Undefined Then
		Item.UserSettingID  = UserSettingID;
	ElsIf Item.ViewMode <>  DataCompositionSettingsItemViewMode.Inaccessible Then
		Item.UserSettingID  = FieldName;
	EndIf;	
	Return Item;
	
EndFunction

// Changes the filter item with the specified field name or presentation.
//
// Parameters:
//  FieldName      - String - data composition field name. Must be filled;
//  ComparisonType - DataCompositionComparisonType - comparison type;
//  RightValue     - Arbitrary - value to be compared;
//  Presentation   - String - data composition item presentation;
//  Use            - Boolean - item usage;
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//
Function ChangeFilterItems(SearchArea,
								Val FieldName = Undefined,
								Val Presentation = Undefined,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If ComparisonType <> Undefined Then
			Item.ComparisonType = ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
	EndDo;
	
	Return ItemArray.Count();
	
EndFunction

// Deletes the filter item with the specified field name or presentation.
// 
// Parameters:
//  AreaToDelete - container with items and groups of the filter, for example
//                 List.Filter or a group in the filter;
//  FieldName    - String - data composition field name (is not used for groups);
//  Presentation - String - data composition field presentation.
// 
Procedure DeleteFilterItems(Val AreaToDelete,
										Val FieldName = Undefined,
										Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(AreaToDelete.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If Item.Parent = Undefined Then
			AreaToDelete.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Adds or replaces the existing filter item.   
// 
// Parameters:
//  WhereToAdd     - container with items and groups of the filter, for example
//                   List.Filter or a group in the filter;
//  FieldName      - String - data composition field name (must always be filled);
//  ComparisonType - DataCompositionComparisonType - comparison type;
//  RightValue     - Arbitrary - value to be compared;
//  Presentation   - String - data composition field presentation;
//  Use            - Boolean - item usage;
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//  UserSettingID  - String - see DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Procedure SetFilterItem(WhereToAdd,
								Val FieldName,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Presentation = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	ModifiedCount = ChangeFilterItems(WhereToAdd, FieldName, Presentation,
							RightValue, ComparisonType, Use, ViewMode);
	
	If ModifiedCount = 0 Then
		If ComparisonType = Undefined Then
			ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		If ViewMode = Undefined Then
			ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		AddCompositionItem(WhereToAdd, FieldName, ComparisonType,
								RightValue, Presentation, Use, ViewMode, UserSettingID);
	EndIf;
	
EndProcedure
 
// Adds or replaces the filter item of the dynamic list.
//
// Parameters:
//  DynamicList    - DynamicList - form attribute that requires the filter to be set.
//  FieldName      - String - data composition field name. Must be filled.
//  RightValue     - Arbitrary - value to be compared.
//  ComparisonType - DataCompositionComparisonType - comparison type.
//  Presentation   - String - data composition field presentation.
//  Use - Boolean  - item usage.
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//  UserSettingID  - String - see  DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Procedure  SetDynamicListFilterItem(DynamicList, FieldName,
	RightValue = Undefined,
	ComparisonType = Undefined,
	Presentation = Undefined,
	Use = Undefined,
	ViewMode = Undefined,
	UserSettingID = Undefined) Export
	
	If ViewMode =  Undefined Then
		ViewMode =  DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName);
	
	SetFilterItem(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		RightValue,
		ComparisonType,
		Presentation,
		Use,
		ViewMode,
		UserSettingID);
	
EndProcedure 
 
// Copies filters from the form parameters to the dynamic list.
//
// Parameters:
// Form        - ManagedForm - form to be a source of the filters.
// DynamicList - DynamicList - Optional. The list where the filter will be set.
//               If the value is not passed the form attribute named List of the corresponding
//               type is expected.
//
// Important: Once the procedure execution finishes, the Form.Paramerets.Filters collection is 
//            cleared. That is why if the Form.Parameres.Filter collection is used in the form
//            script, the procedure must be executed after the execution of such script. For
//            example, in the end of the OnCreateAtServer handler. 
//
Procedure MoveFiltersToDynamicList(Form, DynamicList = Undefined) Export
	Var ComparisonType;
	
	If Not Form.Parameters.Property("Filter")  Then
		Return;
	EndIf;
	If DynamicList = Undefined Then
		DynamicList = Form.List;
	EndIf;
	
	FiltersFromParameters = Form.Parameters.Filter;
	DynamicListFilters = DynamicList.SettingsComposer.Settings.Filter;
	
	Use = True;
	ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	For Each KeyAndValue In FiltersFromParameters Do
		FieldName = KeyAndValue.Key;
		RightValue = KeyAndValue.Value;
		
		If TypeOf(RightValue) = Type("Array") Then
			ComparisonType =  DataCompositionComparisonType.InList;
		ElsIf TypeOf(RightValue) = Type("ValueList") Then
			ComparisonType = DataCompositionComparisonType.InList;
		Else
			ComparisonType = Undefined;
		EndIf;
		
		SetFilterItem(
			DynamicListFilters,
			FieldName,
			RightValue,
			ComparisonType,
			,
			Use,
			ViewMode);
	EndDo;
	
	FiltersFromParameters.Clear();
EndProcedure 
 
// Deletes the filter group item of the dynamic list.
//
// Parameters:
//  DynamicList  - DynamicList - form attribute that requires the filter to be set.
//  FieldName    - String - composition field name. Does not used for groups.
//  Presentation - String - composition field presentation.
//
Procedure DeleteDynamicListFilterCroupItems(DynamicList, FieldName = Undefined, Presentation = Undefined) Export
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName,
		Presentation);
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		Presentation);
 
EndProcedure 
 
// Sets of updates the ParameterName parameter of the List dynamic list.
//
// Parameters:
// List          - DynamicList - form attribute, for which the parameter must be set.
// ParameterName - String - name of the parameter dynamic list.
// Value         - Arbitrary - new parameter value.
// Use           - Boolean - flag that shows whether the parameter is used.
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	DataCompositionParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If DataCompositionParameterValue <> Undefined Then
		If Use And DataCompositionParameterValue.Value <> Value Then
			DataCompositionParameterValue.Value  = Value;
		EndIf;
		If DataCompositionParameterValue.Use <> Use Then
			DataCompositionParameterValue.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure 

////////////////////////////////////////////////////////////////////////////////
// Functions for working with managed forms.
//

// Gets the form attribute value. 
// Parameters:
//  Form          - Managed form;
//  AttributePath - String - data path, for example: "Object.ShippingDate".
//
Function GetFormAttributeByPath(Form, AttributePath) Export
	
	NameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(AttributePath, ".");
	
	Object = Form;
	LastField = NameArray[NameArray.Count()-1];
	
	For Cnt = 0 To NameArray.Count()-2 Do
		Object = Object[NameArray[Cnt]]
	EndDo;
	
	Return Object[LastField];
	
EndFunction

// Sets the value to the form attribute.
// Parameters:
//  Form          - Managed form;
//  AttributePath - String - data path, for example: "Object.ShippingDate".
//  Value         - new value.
//
Procedure SetFormAttributeByPath(Form, AttributePath, Value, NotFilledOnly = False) Export
	
	NameArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(AttributePath, ".");
	
	Object = Form;
	LastField = NameArray[NameArray.Count()-1];
	
	For Cnt = 0 To NameArray.Count()-2 Do
		Object = Object[NameArray[Cnt]]
	EndDo;
	If Not NotFilledOnly Or Not ValueIsFilled(Object[LastField]) Then
		Object[LastField] = Value;
	EndIf;
	
EndProcedure

// Searches for a filter item in the collection by the specified presentation. 
//
// Parameters:
//  WhereToAdd   - container with items and groups of the filter, for example, List.Filter or a
//                 group in the filter;
//  Presentation - String - group presentation.
//
Function FindFilterItemByPresentation(ItemCollection, Presentation) Export
	
	ReturnValue = Undefined;
	
	For Each FilterItem In ItemCollection Do
		If FilterItem.Presentation = Presentation Then
			ReturnValue = FilterItem;
			Break;
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction
 
// Sets the PropertyName property of the ItemName form item to Value.
// Is applied when the form item might be missed on the form because of insufficient user
// rights for an object, an object attribute, or a command.
//
// Parameters:
//  FormItems     - FormItems property of the managed form.
//  ItemName     - String - form item name.
//  PropertyName - String - name of the form item property to be set.
//  Value        - Arbitrary - new item value.
// 
Procedure SetFormItemProperty(FormItems, ItemName, PropertyName, Value) Export
	
	FormItem = FormItems.Find(ItemName);
	If FormItem <> Undefined And FormItem[PropertyName] <> Value Then
		FormItem[PropertyName] = Value;
	EndIf;
	
EndProcedure
 
// Returns the value of the PropertyName property of the ItemName form item.
// Is applied when the form item might be missed on the form because of insufficient user
// rights for an object, an object attribute, or a command.
// 
// Parameters:
//  FormItems - FormItems property of the managed form.
//  ItemName - String - form item name.
//  PropertyName - String - name of the property form item.
// 
// Returns:
//  Arbitrary - value of the PropertyName property of the ItemName form item.
// 
Function FormItemPropertyValue(FormItems, ItemName, PropertyName) Export
	
	FormItem = FormItems.Find(ItemName);
	Return ?(FormItem  <> Undefined, FormItem[PropertyName], Undefined);
	
EndFunction

// Obsolete.
//
// Returns:
//   UsualGroupRepresentation - UsualGroupRepresentation.WeakSeparation.
//
Function UsualGroupRepresentationLine() Export
 
 Return UsualGroupRepresentation.WeakSeparation;
 
EndFunction

// Obsolete.
//
// Returns:
//   UsualGroupRepresentation - UsualGroupRepresentation.NormalSeparation.
//
Function UsualGroupRepresentationMargin() Export
 
 Return UsualGroupRepresentation.NormalSeparation;
 
EndFunction

// Obsolete.
//
// Returns:
//   UsualGroupRepresentation - UsualGroupRepresentation.StrongSeparation.
//
Function UsualGroupRepresentationGroupBorder() Export
 
 Return UsualGroupRepresentation.StrongSeparation;
 
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Predefined data processing
//

// Retrieves a reference to the predefined item by its full name.
// Only tables that can contain predefined items are supported: catalogs, charts of
// characteristic types, charts of accounts, and charts of calculation types.
//
// Parameters:
// PredefinedItemFullName - String - full path to the predefined item including its name.
//                          The format is completely similar to the PredefinedValue() global
//                          context function.
//                          For example:
//                          "Catalog.ContactInformationKinds.UserEmail"
//                          "ChartOfAccounts.ChartOfAccounts.Inventory"
//
// Returns: 
//  AnyRef    - reference to the predefined item.
//  Undefined - if the item is not found.
//
Function PredefinedItem(PredefinedItemFullName) Export
	If Upper(Right(PredefinedItemFullName, 13)) = ".EMPTYREF" Then
		// To receive an empty reference use the standard platform function
		Return PredefinedValue(PredefinedItemFullName);
	EndIf;
	
#If Not ThinClient And Not WebClient And Not ThickClientManagedApplication Then
	Return StandardSubsystemsCached.PredefinedItem(PredefinedItemFullName);
#Else
	Return StandardSubsystemsClientCached.PredefinedItem(PredefinedItemFullName);
#EndIf
	
EndFunction  
 
////////////////////////////////////////////////////////////////////////////////
// Other functions.

// Returns a parameter structure template for establishing an external connection.
// Parameters have to be filled with required values and be passed to the
// CommonUse.EstablishExternalConnection() method.
//
Function ExternalConnectionParameterStructure() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("InfobaseOperationMode", 0);
	ParametersStructure.Insert("InfobaseDirectory", "");
	ParametersStructure.Insert("PlatformServerName", "");
	ParametersStructure.Insert("InfobaseNameAtPlatformServer", "");
	ParametersStructure.Insert("OSAuthentication", False);
	ParametersStructure.Insert("UserName", "");
	ParametersStructure.Insert("UserPassword", "");
	
	Return ParametersStructure;
EndFunction

// Extracts connection parameters from the infobase connection string 
// and passes parameters to structure for setting external connections.
//
Function GetConnectionParametersFromInfobaseConnectionString(Val ConnectionString) Export
	
	Result = ExternalConnectionParameterStructure();
	
	Parameters = StringFunctionsClientServer.GetParametersFromString(ConnectionString);
	
	Parameters.Property("File", Result.InfobaseDirectory);
	Parameters.Property("Srvr", Result.PlatformServerName);
	Parameters.Property("Ref", Result.InfobaseNameAtPlatformServer);
	
	Result.InfobaseOperationMode = ?(Parameters.Property("File"), 0, 1);
	
	Return Result;
EndFunction

// For the file mode, returns the full name of the directory, where the infobase is located.
// If the application runs in the client/server mode, an empty string is returned.
// 
// Returns:
// String - full name of the directory, where the infobase is located.
//
Function FileInfobaseDirectory() Export
	
	ConnectionParameters =  StringFunctionsClientServer.GetParametersFromString(InfobaseConnectionString());
	
	If ConnectionParameters.Property("File") Then
		Return ConnectionParameters.File;
	EndIf;
	
	Return "";
EndFunction
 
// Gets value tree row ID (GetID() method) for the specified tree row field value.
// Is used to determine the cursor position in hierarchical lists.
//
Procedure GetTreeRowIDByFieldValue(FieldName, RowID, TreeItemCollection, RowKey, StopSearch) Export
	
	For Each TreeRow In TreeItemCollection Do
		
		If StopSearch Then
			Return;
		EndIf;
		
		If TreeRow[FieldName] = RowKey Then
			
			RowID = TreeRow.GetID();
			
			StopSearch = True;
			
			Return;
			
		EndIf;
		
		ItemCollection = TreeRow.GetItems();
		
		If ItemCollection.Count() > 0 Then
			
			GetTreeRowIDByFieldValue(FieldName, RowID, ItemCollection, RowKey, StopSearch);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Replaces prohibited characters in the XML string with the specified characters.
// 
// Parameters:
//  Text            – String – prohibited characters in this string will be replaced;
//  ReplacementChar – String – prohibited characters in XML string will be replaced with this string.
// 
// Returns:
//  String - resulting string.
//
Function ReplaceDisallowedXMLCharacters(Val Text, ReplacementChar = " ") Export
	
#If Not WebClient Then
	BeginningPosition = 1;
	While True Do
		Position = FindDisallowedXMLCharacters(Text, BeginningPosition);
		If Position = 0 Then
			Break;
		EndIf;
		If Position > 1 Then
			DisallowedChar = Mid(Text, Position - 1, 1);
			If FindDisallowedXMLCharacters(DisallowedChar) > 0 Then
				Text = StrReplace(Text, DisallowedChar, ReplacementChar);
			EndIf;
		EndIf;
		DisallowedChar = Mid(Text, Position, 1);
		If FindDisallowedXMLCharacters(DisallowedChar) > 0 Then
			Text = StrReplace(Text, DisallowedChar, ReplacementChar);
		EndIf;
		BeginningPosition = Position + 1;
	EndDo;
#EndIf

	Return Text;
EndFunction

// Deletes prohibited characters from the XML string.
// 
// Parameters:
// Text – String – prohibited characters in this string will be deleted.
// 
// Returns:
//  String - resulting string.
//
Function DeleteDisallowedXMLCharacters(Val Text) Export
	
	Return ReplaceDisallowedXMLCharacters(Text, "");
	
EndFunction

// Compares two schedules.
//
// Parameters:
//  Schedule1 - JobSchedule - first schedule.
//  Schedule2 - JobSchedule - second schedule.
//
// Returns
//  Boolean - True if the schedules are equal, otherwise is False.
//
Function SchedulesAreEqual(Val Schedule1, Val Schedule2) Export
	
	Return String(Schedule1) = String(Schedule2);
	
EndFunction 
 
// Returns the code of the default configuration language, for example, "en".
Function DefaultLanguageCode() Export
	#If Not ThinClient  And Not WebClient Then
		Return Metadata.DefaultLanguage.LanguageCode;
	#Else
		Return StandardSubsystemsClientCached.ClientParameters().DefaultLanguageCode;
	#EndIf
EndFunction  
 
// Returns True if a client application is connected to the infobase through a web server.
// Returns False if there is no client application.
//
Function ClientConnectedViaWebServer() Export
	
#If Client Or  ExternalConnection Then
	InfobaseConnectionString =  InfobaseConnectionString();
#Else
	SetPrivilegedMode(True);
	
	InfobaseConnectionString =  StandardSubsystemsServer.ClientParametersOnServer(
		).Get("InfobaseConnectionString");
	
	If InfobaseConnectionString = Undefined Then
		Return False; // No client application
	EndIf;
#EndIf
	
	Return Find(Upper(InfobaseConnectionString),  "WS=")  = 1;
	
EndFunction 
 
// Returns True if the client application runs on Linux.
//
// Returns:
//  Boolean. Returns False if there is no client application.
//
Function IsLinuxClient()  Export
	
#If Client Or  ExternalConnection Then
	SystemInfo = New SystemInfo;
	
	IsLinuxClient = SystemInfo.PlatformType = PlatformType.Linux_x86
	 Or SystemInfo.PlatformType = PlatformType.Linux_x86_64;
#Else
	SetPrivilegedMode(True);
	
	IsLinuxClient = StandardSubsystemsServer.ClientParametersOnServer().Get("IsLinuxClient");
	
	If IsLinuxClient = Undefined Then
		Return False; // No client application
	EndIf;
#EndIf
	
	Return IsLinuxClient;
	
EndFunction 
 
// Returns True if the client application is a web client.
//
// Returns:
//  Boolean. Returns False if there is no client application.
//
Function IsWebClient()  Export
	
#If WebClient Then
	Return True;
#ElsIf Client Or ExternalConnection Then
	Return False;
#Else
	SetPrivilegedMode(True);
	
	IsWebClient = StandardSubsystemsServer.ClientParametersOnServer().Get("IsWebClient");
	
	If IsWebClient = Undefined Then
		Return False; // No client application
	EndIf;
	
	Return IsWebClient;
#EndIf
	
EndFunction  
 
// Raises an exception with Message if Condition is not True.
// Is applied for script self-diagnostics.
//
// Parameters:
//  Where               - Boolean - if it is not True, the extension is raised.
//  VerificationContext - String - for example, a name of procedure or function where the
//                        verification is executed.
//  Message             - String - message text. If it is not specified, the exception is
//                        raised with the default message.
//
Procedure Validate(Val Where, Val Message = "", Val  VerificationContext = "") Export
	
	If Where <>  True Then
		If IsBlankString(Message) Then
			ErrorMessage = NStr("en = 'Invalid operation'"); // Assertion failed
		Else
			ErrorMessage = Message;
		EndIf;
		If Not  IsBlankString(VerificationContext)  Then
			ErrorMessage = ErrorMessage + " " +
				StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'in %1'"), VerificationContext);
		EndIf;
		Raise ErrorMessage;
	EndIf;
	
EndProcedure
  
// Raises an exception if the ParameterName parameter value type of the ProcedureOrFunctionName 
// procedure or function does not match the excepted one.

// Is intended for validating types of parameters passed to the interface procedures and 
// functions.
//
// Parameters:
//  ProcedureOrFunctionName - String - name of a procedure or function whose parameter is
//                            validated.
//  ParameterName           - String - name of the procedure or function parameter to be
//                            validated.
//  ParameterValue          - Arbitrary - actual parameter value.
//  ExpectedTypes           - TypeDescription, Type - parameter type(s) of the procedure or
//                            function.
//  ExpectedPropertyTypes   - Structure - if the expected type is a structure, one can specify
//                            types of its properties.
//
Procedure ValidateParameter(Val ProcedureOrFunctionName, Val ParameterName, Val ParameterValue, 
	Val ExpectedTypes, Val ExpectedPropertyTypes = Undefined) Export
	
	Context = "CommonUseClientServer.ValidateParameter";
	Validate(TypeOf(ProcedureOrFunctionName) = Type("String"), 
		NStr("en = 'The ProcedureOrFunctionName parameter value is not valid'"), Context);
	Validate(TypeOf(ParameterName) = Type("String"), 
		NStr("en = 'The ParameterName parameter value is not valid'"), Context);
		
	IsTypeDescription = TypeOf(ExpectedTypes) = Type("TypeDescription");
	Validate(IsTypeDescription Or TypeOf(ExpectedTypes) = Type("Type"), 
		NStr("en = 'The ExpectedTypes parameter value is not valid'"), Context);
		
	InvalidParameter = NStr("en = '%1 parameter value in %2 is not valid. 
		|Expected: %3; Passed value: %4 (%5 type).'");
	Validate((IsTypeDescription And ExpectedTypes.ContainsType(TypeOf(ParameterValue)))
		Or (Not IsTypeDescription And  ExpectedTypes = TypeOf(ParameterValue)), 
		StringFunctionsClientServer.SubstituteParametersInString(InvalidParameter, 
			ParameterName, ProcedureOrFunctionName, ExpectedTypes, 
			?(ParameterValue <> Undefined, ParameterValue, NStr("en = 'Undefined'")),  TypeOf(ParameterValue)));
			
	If TypeOf(ParameterValue) = Type("Structure") And ExpectedPropertyTypes <>  Undefined Then
		
		Validate(TypeOf(ExpectedPropertyTypes) = Type("Structure"), 
			NStr("en = 'The ProcedureOrFunctionName parameter value is not valid'"), Context);
			
		NoProperty = NStr("en = '%1 (Structure) parameter value in %2 is not valid. 
			|The %3 property (%4 type) was expected in the structure.'");
		InvalidProperty = NStr("en = '%1 property value in %2 (Structure) parameter in %3 is not valid. 
			|Expected: %4; Passed value: %5 (%6 type).'");
		For Each Property  In ExpectedPropertyTypes Do
			
			ExpectedPropertyName = Property.Key;

			ExpectedPropertyType = Property.Value;
			PropertyValue = Undefined;
			
			Validate(ParameterValue.Property(ExpectedPropertyName, PropertyValue), 
				StringFunctionsClientServer.SubstituteParametersInString(NoProperty, 
					ParameterName, ProcedureOrFunctionName, ExpectedPropertyName,  ExpectedPropertyType));
					
			IsTypeDescription = TypeOf(ExpectedPropertyType) = Type("TypeDescription");
			Validate((IsTypeDescription And ExpectedPropertyType.ContainsType(TypeOf(PropertyValue)))
				Or (Not IsTypeDescription And  ExpectedPropertyType = TypeOf(PropertyValue)), 
				StringFunctionsClientServer.SubstituteParametersInString(InvalidProperty, 
					ExpectedPropertyName, ParameterName, ProcedureOrFunctionName,  ExpectedPropertyType, 
					?(PropertyValue <> Undefined, PropertyValue, NStr("en = 'Undefined'")),  TypeOf(PropertyValue)));

					
		EndDo;	
	EndIf;		
	
EndProcedure  
 
////////////////////////////////////////////////////////////////////////////////
// Math procedures and functions

// Distributes the amount according to the specified distribution ratios.
//
// Parameters:
// 	SrcAmount  - amount to be distributed.
// 	RatioArray - array of the distribution ratios.
// 	Accuracy   - round-off accuracy when distributing. Optional.
//
// Returns:
//  AmountArray - array whose dimension are equal to the number of ratios, contains amounts
//                according to the ratio weights (from the array of ratios). If the function
//                cannot distribute the amount (amount = 0, number of ratios = 0, or the total
//                ratio weight = 0), Undefined is returned.
//
Function  DistributeAmountProportionallyCoefficients(Val SrcAmount, RatioArray, Val Accuracy = 2) Export
	
	If RatioArray.Count() = 0 Or Not ValueIsFilled(SrcAmount) Then
		Return Undefined;
	EndIf;
	
	MaxIndex = 0;
	MaxVal = 0;
	DistribAmount = 0;
	AmountCoeff = 0;
	
	For K = 0 to RatioArray.Count() - 1 Do
		
		AbsNumber = ?(RatioArray[K] > 0, RatioArray[K], - RatioArray[K]);
		
		If MaxVal < AbsNumber Then
			MaxVal = AbsNumber;
			MaxIndex = K;
		EndIf;
		
		AmountCoeff = AmountCoeff + RatioArray[K];
		
	EndDo;
	
	If AmountCoeff = 0 Then
		Return Undefined;
	EndIf;
	
	AmountArray = New  Array(RatioArray.Count());
	
	For K = 0 to RatioArray.Count() - 1 Do
		AmountArray[K] = Round(SrcAmount * RatioArray[K] / AmountCoeff,  Accuracy, 1);
		DistribAmount = DistribAmount + AmountArray[K];
	EndDo;
	
	// Adding the round-off error to the ratio with the maximum weight
	If Not DistribAmount = SrcAmount Then
		AmountArray[MaxIndex] = AmountArray[MaxIndex] + SrcAmount -  DistribAmount;
	EndIf;
	
	Return AmountArray;
	
EndFunction  
 
////////////////////////////////////////////////////////////////////////////////

// Obsolete. All usages of this functions should be deleted and scripts that work in case of False returned too.
//
Function IsPlatform83WithoutCompatibilityMode() Export
 Return True;
EndFunction

// Obsolete. All usages of this functions should be deleted and scripts that work in case of False returned too.
//
Function IsPlatform83() Export
 Return True;
EndFunction

// AUXILIARY PROCEDURES AND FUNCTIONS 

// Searches for the item in the value list or in the array.
//
Function FindInList(List, Item)
	
	Var ItemInList;
	
	If TypeOf(List) = Type("ValueList") Then
		If TypeOf(Item) = Type("ValueListItem") Then
			ItemInList = List.FindByValue(Item.Value);
		Else
			ItemInList = List.FindByValue(Item);
		EndIf;
	EndIf;
	
	If TypeOf(List) = Type("Array") Then
		ItemInList = List.Find(Item);
	EndIf;
	
	Return ItemInList;
	
EndFunction

// Checks that email address does not contain border characters.
// If border characters is used correctly, the procedure deletes them.
//
Function CheckAndPrepareEmailAddress(Val AddresseeFullName, Val EmailAddress)
	
	ProhibitedCharInRecipientName = NStr("en = 'There is a prohibited character in the addressee name.'");
	EmailContainsProhibitedChar = NStr("en = 'There is a prohibited character in the email address.'");
	BorderChars = "<>[]";
	
	EmailAddress      = TrimAll(EmailAddress);
	AddresseeFullName = TrimAll(AddresseeFullName);
	
	If Left(AddresseeFullName, 1) = "<" Then
		If Right(AddresseeFullName, 1) = ">" Then
			AddresseeFullName = Mid(AddresseeFullName, 2, StrLen(AddresseeFullName)-2);
		Else
			Raise ProhibitedCharInRecipientName;
		EndIf;
	ElsIf Left(AddresseeFullName, 1) = "[" Then
		If Right(AddresseeFullName, 1) = "]" Then
			AddresseeFullName = Mid(AddresseeFullName, 2, StrLen(AddresseeFullName)-2);
		Else
			Raise ProhibitedCharInRecipientName;
		EndIf;
	EndIf;
	
	If Left(EmailAddress, 1) = "<" Then
		If Right(EmailAddress, 1) = ">" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise EmailContainsProhibitedChar;
		EndIf;
	ElsIf Left(EmailAddress, 1) = "[" Then
		If Right(EmailAddress, 1) = "]" Then
			EmailAddress = Mid(EmailAddress, 2, StrLen(EmailAddress)-2);
		Else
			Raise EmailContainsProhibitedChar;
		EndIf;
	EndIf;
	
	For Index = 1 to StrLen(BorderChars) Do
		If Find(AddresseeFullName, Mid(BorderChars, Index, 1)) <> 0
		 Or Find(EmailAddress, Mid(BorderChars, Index, 1)) <> 0 Then
			Raise EmailContainsProhibitedChar;
		EndIf;
	EndDo;
	
	Return New Structure("Address, Presentation", EmailAddress,AddresseeFullName);
	
EndFunction

// Shifts a position marker while the current character is the SkippedChar.
// Returns number of marker position.
//
Function SkipChars(Val String,
                   Val CurrentIndex,
                   Val SkippedChar)
	
	Result = CurrentIndex;
	
	// Removes skipped characters, if any
	While CurrentIndex < StrLen(String) Do
		If Mid(String, CurrentIndex, 1) <> SkippedChar Then
			Return CurrentIndex;
		EndIf;
		CurrentIndex = CurrentIndex + 1;
	EndDo;
	
	Return CurrentIndex;
	
EndFunction

Procedure FindRecursively(ItemCollection, ItemArray, SearchMethod, SearchValue)
	
	For Each FilterItem In ItemCollection Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterItem.LeftValue = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterItem.Presentation = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterItem.Items, ItemArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterItem.Presentation = SearchValue Then
				ItemArray.Add(FilterItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function ReplaceCharsInStringWithSpaces(String, CharsToReplace)
	Result = String;
	For Position = 1 to StrLen(Chars) Do
		Result = StrReplace(Result, Mid(CharsToReplace, Position, 1), " ");
	EndDo;
	Return Result;
EndFunction

Function HasCharsLeftRight(String, CharsToCheck)
	For Position = 1 to StrLen(CharsToCheck) Do
		Char = Mid(CharsToCheck, Position, 1);
		CharFound = (Left(String,1) = Char) Or (Right(String,1) = Char);
		If CharFound Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

Function StringContainsAllowedCharsOnly(String, AllowedChars)
	CharacterArray = New Array;
	For Position = 1 to StrLen(AllowedChars) Do
		CharacterArray.Add(Mid(AllowedChars,Position,1));
	EndDo;
	
	For Position = 1 to StrLen(String) Do
		If CharacterArray.Find(Mid(String, Position, 1)) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction
 
#EndRegion