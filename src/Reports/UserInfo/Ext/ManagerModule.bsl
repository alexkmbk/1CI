#If Server OR ThickClientOrdinaryApplication OR ExternalConnection Then

#Region InternalInterface

// Report pane layout settings.
//
// Parameters:
//   Settings       - Collection - is used to set report settings and report options. 
//       See the description of ReportOptions.ConfigurationReportOptionSettingsTree().
//   ReportSettings - ValueTreeRow - layout settings for all report options
//       See "Attributes that can be changed" in the
//       ReportOptions.ConfigurationReportOptionSettingsTree() function.
//
// Details:
//   See ReportOptionsOverridable.SetupReportOptions().
//
// Auxiliary methods:
//   OptionSettings = ReportOptions.OptionDetails(Settings, ReportSettings, "<OptionName>");
//   ReportOptions.SetOutputModeInReportPane(Settings, ReportSettings, True/False); 
// The report can be generated only in this mode.
//
Procedure SetUpReportOptions(Settings, ReportSettings) Export
	ReportOptionsModule = CommonUse.CommonModule("ReportOptions");
	
	OptionSettings = ReportOptionsModule.OptionDetails(Settings, ReportSettings, "UserAndExternalUserInfo");
	OptionSettings.Details = 
		NStr("en = 'Displays detailed info about all users, including logon settings (if they are specified).'");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
	
	OptionSettings = ReportOptionsModule.OptionDetails(Settings, ReportSettings, "UserInfo");
	OptionSettings.Details = 
		NStr("en = 'Displays detailed user info, including logon settings (if they are specified).'");
	
	OptionSettings = ReportOptionsModule.OptionDetails(Settings, ReportSettings, "ExternalUserInfo");
	OptionSettings.Details = 
		NStr("en = 'Displays detailed external user info, including logon settings (if they are specified).'");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInfo, StandardProcessing)
	
	If Not Parameters.Property("VariantKey") Then
		StandardProcessing = False;
		Parameters.Insert("VariantKey", "UserAndExternalUserInfo");
		SelectedForm = "Report.UserInfo.Form";
	EndIf;
	
EndProcedure

#EndRegion
