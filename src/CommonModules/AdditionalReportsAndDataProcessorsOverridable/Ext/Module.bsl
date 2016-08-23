////////////////////////////////////////////////////////////////////////////////
// Additional reports and data processors subsystem.
// 
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Defines the sections where the command that opens an additional data processor is available.
//
// Parameters:
//     Sections - Array - Defines the sections where the command that opens an additional data processor is available.
//             * MetadataObject: Subsystem - Section (subsystems) metadata.
//             * String - Desktop section.
//
// Details:
//     Add the metadata of sections where the commands are available to the Sections array.
//
//     To include the desktop, add AdditionalReportsAndDataProcessorsClientServer.DesktopID() instead of metadata.
//  
Procedure GetSectionsWithAdditionalDataProcessors(Sections) Export
	
	// _Demo begin example
	Sections.Add(AdditionalReportsAndDataProcessorsClientServer.DesktopID());
	//Sections.Add(Metadata.Subsystems._DemoIntegrableSubsystems);
	// _Demo end example
	
EndProcedure

// Defines the sections where the command that opens an additional report is available.
//
// Parameters:
//     Sections - Array - Sections where commands that open additional reports are available.
//             * MetadataObject: Subsystem - Section (subsystems) metadata.
//             * String - Desktop section.
//
// Details:
//     Add the metadata of sections where the command is available to the Sections array.
//
//     To include the desktop, add AdditionalReportsAndDataProcessorsClientServer.DesktopID() instead of metadata.
//  
Procedure GetSectionsWithAdditionalReports(Sections) Export
	
	// _Demo begin example
	Sections.Add(AdditionalReportsAndDataProcessorsClientServer.DesktopID());
	Sections.Add(Metadata.Subsystems.Administration);
	// _Demo end example
	
EndProcedure

#EndRegion
