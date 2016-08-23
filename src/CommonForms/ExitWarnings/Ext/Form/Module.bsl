
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form will be received if the SelfTest parameter is passed.
	If Parameters.Property("SelfTest") Then 
		Return;
	EndIf;
		
	Key = "";
	For Each Warning In Parameters.Warnings Do
		Key = Key + Warning.ActionIfMarked.Form + Warning.ActionOnHyperlinkClick.Form;
	EndDo;
	Hash = New DataHashing(HashFunction.MD5);
	Hash.Append(Key);
	WindowOptionsKey = "ExitWarnings" + StrReplace(Hash.HashSum, " ", "");
	
	InitFormItems(Parameters.Warnings);
	StandardSubsystemsServer.SetGroupTitleRepresentation(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

&AtClient
Procedure HyperlinkClick(Item)
	ItemName = Item.Name;
	
	For Each QuestionString In ItemsAndParametersMapArray Do
		QuestionParameters = New Structure("Name, Form, FormParameters");
		
		FillPropertyValues(QuestionParameters, QuestionString.Value);
		If ItemName = QuestionParameters.Name Then 
			
			If QuestionParameters.Form <> Undefined Then
				OpenForm(QuestionParameters.Form, QuestionParameters.FormParameters, ThisObject);
			EndIf;
			
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient 
Procedure CheckBoxOnChange(Item)
	
	ItemName  = Item.Name;
	FoundItem = Items.Find(ItemName);
	
	If FoundItem = Undefined Then 
		Return;
	EndIf;
	
	ElementValue = ThisObject[ItemName];
	If TypeOf(ElementValue) <> Type("Boolean") Then
		Return;
	EndIf;

	ArrayID = TaskIDByName(ItemName);
	If ArrayID = Undefined Then 
		Return;
	EndIf;
	
	ArrayElement = TaskArrayToExecuteOnClose.FindByID(ArrayID);
	
	Use = Undefined;
	If ArrayElement.Value.Property("Use", Use) Then 
		If TypeOf(Use) = Type("Boolean") Then 
			ArrayElement.Value.Use = ElementValue;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExitApp(Command)
	
	ExecuteTasksOnClose();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(True);
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Creates form items by questions to a user.
//
// Parameters:
// Questions - Array - structures with parameters of question values.
//             See StandardSubsystems.BaseFunctionality\OnGetExitWarningList.
//

&AtServer
Procedure InitFormItems(Val Warnings)
	
	// Adding the option to skip setting the default value
	WarningTable = StructureArrayIntoValueTable(Warnings);
	
	For Each CurrentWarning In WarningTable Do 
		
		// Adding the item to the form only if a flag text or a hyperlink text is
		// specified, but not both at the same time.
		ReferenceNeeded = Not IsBlankString(CurrentWarning.HyperlinkText);
		FlagNeeded      = Not IsBlankString(CurrentWarning.CheckBoxText);
		
		If ReferenceNeeded And FlagNeeded Then
			Continue;
			
		ElsIf ReferenceNeeded Then
			CreateHyperlinkOnForm(CurrentWarning);
			
		ElsIf FlagNeeded Then
			CreateCheckBoxOnForm(CurrentWarning);
			
		EndIf;
		
	EndDo;
	
	// Footer.
	LabelText = NStr("en = 'Do you want to exit the application?'");
	
	LabelName  = FindLabelNameOnForm("QuestionLabel");
	LabelGroup = GenerateFormItemGroup();
	
	InformationTextItem = Items.Add(LabelName, Type("FormDecoration"), LabelGroup);
	InformationTextItem.VerticalAlign = ItemVerticalAlign.Bottom;
	InformationTextItem.Title         = LabelText;
	InformationTextItem.Height        = 2;
	
EndProcedure

&AtServer
Function StructureArrayIntoValueTable(Val Warnings)
	
	// Generates the table that contains default values
	WarningTable = New ValueTable;
	WarningColumns = WarningTable.Columns;
	WarningColumns.Add("InformationText");
	WarningColumns.Add("CheckBoxText");
	WarningColumns.Add("ActionIfMarked");
	WarningColumns.Add("HyperlinkText");
	WarningColumns.Add("ActionOnHyperlinkClick");
	WarningColumns.Add("Priority");
	WarningColumns.Add("DisplaySingleWarning");
	WarningColumns.Add("ExtendedTooltip");
	
	SingleWarnings = New Array;
	
	For Each WarningItem In Warnings Do
		TableRow = WarningTable.Add();
		FillPropertyValues(TableRow, WarningItem);
		
		If TableRow.DisplaySingleWarning = True Then
			SingleWarnings.Add(TableRow);
		EndIf;
	EndDo;
	
	// If there is at least one warning that required clearing (DisplaySingleWarning = True), clearing other ones.
	If SingleWarnings.Count() > 0 Then
		WarningTable = WarningTable.Copy(SingleWarnings);
	EndIf;
	
	// Higher priority - higher in the list.
	WarningTable.Sort("Priority Desc");
	
	Return WarningTable;
EndFunction

&AtServer
Function GenerateFormItemGroup()
	
	GroupName = FindLabelNameOnForm("GroupOnForm");
	
	Group = Items.Add(GroupName, Type("FormGroup"), Items.MainGroup);
	Group.Kind = FormGroupType.UsualGroup;
	
	Group.HorizontalStretch = True;
	Group.ShowTitle         = False;
	Group.Representation    = UsualGroupRepresentation.None;
	
	Return Group; 
	
EndFunction

&AtServer
Procedure CreateHyperlinkOnForm(QuestionStructure)
	
	Group = GenerateFormItemGroup();
	
	If Not IsBlankString(QuestionStructure.InformationText) Then 
		LabelName = FindLabelNameOnForm("QuestionLabel");
		LabelType = Type("FormDecoration");
		
		LabelParent = Group;
		
		InformationTextItem = Items.Add(LabelName, LabelType, LabelParent);
		InformationTextItem.Title = QuestionStructure.InformationText;
	EndIf;
	
	If IsBlankString(QuestionStructure.HyperlinkText) Then
		Return;
	EndIf;
	
	// Creating a hyperlink
	HyperlinkName = FindLabelNameOnForm("QuestionLabel");
	HyperlinkType = Type("FormDecoration");
	
	HiperlinkParent = Group;

	HyperlinkItem = Items.Add(HyperlinkName, HyperlinkType, HiperlinkParent);
	HyperlinkItem.Hyperlink = True;
	HyperlinkItem.Title     = QuestionStructure.HyperlinkText;
	HyperlinkItem.SetAction("Click", "HyperlinkClick");
	
	SetExtendedTooltip(HyperlinkItem, QuestionStructure);
	
	ProcessingStructure = QuestionStructure.ActionOnHyperlinkClick;
	If IsBlankString(ProcessingStructure.Form) Then
		Return;
	EndIf;
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Name", HyperlinkName);
	FormOpenParameters.Insert("Form", ProcessingStructure.Form);
	
	FormParameters = ProcessingStructure.FormParameters;
	If FormParameters = Undefined Then 
		FormParameters = New Structure;
	EndIf;
	FormParameters.Insert("ExitApplication", True);
	FormOpenParameters.Insert("FormParameters", FormParameters);
	
	ItemsAndParametersMapArray.Add(FormOpenParameters);
		
EndProcedure

&AtServer
Procedure CreateCheckBoxOnForm(QuestionStructure)
	
	DefaultValue = True;
	Group = GenerateFormItemGroup();
	
	If Not IsBlankString(QuestionStructure.InformationText) Then
		LabelName = FindLabelNameOnForm("QuestionLabel");
		LabelType = Type("FormDecoration");
		
		LabelParent = Group;
		
		InformationTextItem = Items.Add(LabelName, LabelType, LabelParent);
		InformationTextItem.Title = QuestionStructure.InformationText;
	EndIf;
	
	If IsBlankString(QuestionStructure.CheckBoxText) Then 
		Return;
	EndIf;
	
	// Adding the attribute to the form.
	FlagName = FindLabelNameOnForm("QuestionLabel");
	FlagType = Type("FormField");
	
	FlagParent = Group;
	
	TypeArray = New Array;
	TypeArray.Add(Type("Boolean"));
	Details = New TypeDescription(TypeArray);
	
	AttributesToBeAdded = New Array;
	NewAttribute = New FormAttribute(FlagName, Details, , FlagName, False);
	AttributesToBeAdded.Add(NewAttribute);
	ChangeAttributes(AttributesToBeAdded);
	ThisObject[FlagName] = DefaultValue;
	
	NewFormField = Items.Add(FlagName, FlagType, FlagParent);
	NewFormField.DataPath = FlagName;
	
	NewFormField.TitleLocation = FormItemTitleLocation.Right;
	NewFormField.Title         = QuestionStructure.CheckBoxText;
	NewFormField.Kind          = FormFieldType.CheckBoxField;
	
	SetExtendedTooltip(NewFormField, QuestionStructure);
	
	If IsBlankString(QuestionStructure.ActionIfMarked.Form) Then
		Return;	
	EndIf;
	
	ActionStructure = QuestionStructure.ActionIfMarked;
	
	NewFormField.SetAction("OnChange", "CheckBoxOnChange");
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Name", FlagName);
	FormOpenParameters.Insert("Form", ActionStructure.Form);
	FormOpenParameters.Insert("Use", DefaultValue);
	
	FormParameters = ActionStructure.FormParameters;
	If FormParameters = Undefined Then 
		FormParameters = New Structure;
	EndIf;
	FormParameters.Insert("ExitApplication", True);
	FormOpenParameters.Insert("FormParameters", FormParameters);
	
	TaskArrayToExecuteOnClose.Add(FormOpenParameters);
	
EndProcedure

&AtServer
Procedure SetExtendedTooltip(FormItem, Val DescriptionString)
	
	ExtendedTooltipDetails = DescriptionString.ExtendedTooltip;
	If ExtendedTooltipDetails = "" Then
		Return;
	EndIf;
	
	If TypeOf(ExtendedTooltipDetails) <> Type("String") Then
		// Setting the extended tooltip
		FillPropertyValues(FormItem.ExtendedTooltip, ExtendedTooltipDetails);
		FormItem.ToolTipRepresentation = ToolTipRepresentation.Button;
		Return;
	EndIf;
	
	FormItem.ExtendedTooltip.Title = ExtendedTooltipDetails;
	FormItem.ToolTipRepresentation = ToolTipRepresentation.Button;
	
EndProcedure

&AtServer
Function FindLabelNameOnForm(ItemTitle)
	Index = 0;
	SearchFlag = True;
	
	While SearchFlag Do 
		RowIndex = String(Format(Index, "NZ=-"));
		RowIndex = StrReplace(RowIndex, "-", "");
		Name = ItemTitle + RowIndex;
		
		FoundItem = Items.Find(Name);
		If FoundItem = Undefined Then 
			Return Name;
		EndIf;
		
		Index = Index + 1;
	EndDo;
EndFunction	

&AtClient
Function TaskIDByName(ItemName)
	For Each ArrayElement In TaskArrayToExecuteOnClose Do
		Description = "";
		If ArrayElement.Value.Property("Name", Description) Then 
			If Not IsBlankString(Description) And Description = ItemName Then
				Return ArrayElement.GetID();
			EndIf;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

&AtClient
Procedure ExecuteTasksOnClose(Result = Undefined, InitialTaskNumber = Undefined) Export
	
	If InitialTaskNumber = Undefined Then
		InitialTaskNumber = 0;
	EndIf;
	
	For TaskNumber = InitialTaskNumber to TaskArrayToExecuteOnClose.Count() - 1 Do
		
		ArrayElement = TaskArrayToExecuteOnClose[TaskNumber];
		Use = Undefined;
		If Not ArrayElement.Value.Property("Use", Use) Then 
			Continue;
		EndIf;
		If TypeOf(Use) <> Type("Boolean") Then 
			Continue;
		EndIf;
		If Use <> True Then 
			Continue;
		EndIf;
		
		Form = Undefined;
		If ArrayElement.Value.Property("Form", Form) Then 
			FormParameters = Undefined;
			If ArrayElement.Value.Property("FormParameters", FormParameters) Then 
				Notification = New NotifyDescription("ExecuteTasksOnClose", ThisObject, TaskNumber + 1);
				OpenForm(Form, StructureFromFixedStructure(FormParameters),,,,,Notification, FormWindowOpeningMode.LockOwnerWindow);
				Return;
			EndIf;
		EndIf;
	EndDo;
	
	Close(False);
	
EndProcedure

&AtClient
Function StructureFromFixedStructure(Source)
	
	Result = New Structure;
	
	For Each Item In Source Do
		Result.Insert(Item.Key, Item.Value);
	EndDo;
	
	Return Result;
EndFunction

#EndRegion
