////////////////////////////////////////////////////////////////////////////////
// Base functionality subsystem.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Interface

// Defines the list of configuration and library modules that provide the following 
// general details: name, version, update handler list, and its dependence on other
// libraries.
//
// See the content of the mandatory module procedures in the INTERFACE section of the
// InfobaseUpdateSL common module.
//
// Parameters:
//  SubsystemModules - Array - names of the common server library modules and the
//                             configuration. For example: InfobaseUpdateSL.
//                    
// Note: there is no need to add the InfobaseUpdateSL module to the SubsystemModules
// array.
//
Procedure SubsystemsOnAdd(SubsystemModules) Export
	
	//PARTIALLY_DELETED
	// _Demo beginning example
	//SubsystemModules.Add("_DemoInfobaseUpdateSL");
	// _Demo the end example
	
	// CI >
	// CloudTechnology
	//SubsystemModules.Add("InfobaseUpdateCTL");
	// End CloudTechnology
	// CI <
EndProcedure

#EndRegion